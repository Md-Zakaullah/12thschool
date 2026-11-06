-- Vidya Campus schema. Run once in the Supabase SQL editor.
create type user_role as enum ('admin','principal','teacher','student','parent','warden','accountant');

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null,
  role user_role not null default 'student',
  phone text,
  created_at timestamptz not null default now()
);
create table classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  section text not null,
  unique (name, section)
);
create table students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references profiles(id) on delete set null,
  admission_no text unique not null,
  class_id uuid references classes(id) on delete set null,
  roll_no int,
  dob date,
  guardian_id uuid references profiles(id) on delete set null,
  is_hosteller boolean not null default false
);
create table attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  date date not null,
  status text not null check (status in ('present','absent','late','leave')),
  marked_by uuid references profiles(id) on delete set null,
  unique(student_id,date)
);
create table fee_invoices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  title text not null,
  amount numeric(10,2) not null check (amount >= 0),
  due_date date,
  status text not null default 'pending' check (status in ('pending','paid','overdue','cancelled'))
);
create table hostels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  gender text
);
create table rooms (
  id uuid primary key default gen_random_uuid(),
  hostel_id uuid not null references hostels(id) on delete cascade,
  room_no text not null,
  floor int,
  capacity int not null check (capacity > 0),
  unique(hostel_id, room_no)
);
create table beds (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references rooms(id) on delete cascade,
  bed_no text not null,
  student_id uuid unique references students(id) on delete set null,
  unique(room_id, bed_no)
);
create table outpass_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  reason text not null,
  from_ts timestamptz not null,
  to_ts timestamptz not null,
  parent_status text not null default 'pending' check (parent_status in ('pending','approved','rejected')),
  warden_status text not null default 'pending' check (warden_status in ('pending','approved','rejected')),
  check (to_ts > from_ts)
);

create function current_role_name() returns user_role
language sql stable security definer
set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create function handle_new_user() returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name','New user'));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function handle_new_user();

alter table profiles enable row level security;
alter table classes enable row level security;
alter table students enable row level security;
alter table attendance enable row level security;
alter table fee_invoices enable row level security;
alter table hostels enable row level security;
alter table rooms enable row level security;
alter table beds enable row level security;
alter table outpass_requests enable row level security;

create policy "profile self or admin read" on profiles for select
using (id = auth.uid() or current_role_name() in ('admin','principal'));
create policy "admin manages profiles" on profiles for all
using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

create policy "staff reads classes" on classes for select
using (current_role_name() in ('admin','principal','teacher','accountant','warden'));
create policy "admin manages classes" on classes for all
using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

create policy "staff manages students" on students for all
using (current_role_name() in ('admin','principal','teacher','warden','accountant'))
with check (current_role_name() in ('admin','principal','teacher','warden','accountant'));
create policy "student or guardian reads own record" on students for select
using (profile_id = auth.uid() or guardian_id = auth.uid());

create policy "staff manages attendance" on attendance for all
using (current_role_name() in ('admin','principal','teacher'))
with check (current_role_name() in ('admin','principal','teacher'));
create policy "student or guardian reads attendance" on attendance for select
using (student_id in (select id from students where profile_id = auth.uid() or guardian_id = auth.uid()));

create policy "accounts manage invoices" on fee_invoices for all
using (current_role_name() in ('admin','accountant'))
with check (current_role_name() in ('admin','accountant'));
create policy "student or guardian reads invoices" on fee_invoices for select
using (student_id in (select id from students where profile_id = auth.uid() or guardian_id = auth.uid()));

create policy "staff reads hostel data" on hostels for select
using (current_role_name() in ('admin','principal','warden'));
create policy "admins and wardens manage hostels" on hostels for all
using (current_role_name() in ('admin','warden')) with check (current_role_name() in ('admin','warden'));
create policy "staff reads rooms" on rooms for select
using (current_role_name() in ('admin','principal','warden'));
create policy "admins and wardens manage rooms" on rooms for all
using (current_role_name() in ('admin','warden')) with check (current_role_name() in ('admin','warden'));
create policy "staff reads beds" on beds for select
using (current_role_name() in ('admin','principal','warden'));
create policy "admins and wardens manage beds" on beds for all
using (current_role_name() in ('admin','warden')) with check (current_role_name() in ('admin','warden'));

create policy "student guardian or staff reads outpass" on outpass_requests for select
using (
  student_id in (select id from students where profile_id = auth.uid() or guardian_id = auth.uid())
  or current_role_name() in ('admin','principal','warden')
);
create policy "student creates own outpass" on outpass_requests for insert
with check (student_id in (select id from students where profile_id = auth.uid()));
create policy "parent or warden processes outpass" on outpass_requests for update
using (
  student_id in (select id from students where guardian_id = auth.uid())
  or current_role_name() in ('admin','warden')
)
with check (
  student_id in (select id from students where guardian_id = auth.uid())
  or current_role_name() in ('admin','warden')
);

-- FIRST ADMIN: signup ke baad apne verified account ke liye admin role set karein:
-- update public.profiles set role='admin'
-- where id = (select id from auth.users where email='you@school.com');


-- Restrict outpass updates to the approval field owned by the caller's role.
-- Admins may update all fields; parents may only set parent_status;
-- wardens may only set warden_status.
create or replace function enforce_outpass_update_scope() returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role user_role;
begin
  caller_role := current_role_name();

  if caller_role = 'admin' then
    return new;
  end if;

  if caller_role = 'parent'
     and exists (select 1 from public.students s where s.id = old.student_id and s.guardian_id = auth.uid())
     and (to_jsonb(new) - 'parent_status') = (to_jsonb(old) - 'parent_status')
     and old.parent_status = 'pending'
     and new.parent_status in ('approved', 'rejected') then
    return new;
  end if;

  if caller_role = 'warden'
     and (to_jsonb(new) - 'warden_status') = (to_jsonb(old) - 'warden_status')
     and old.warden_status = 'pending'
     and new.warden_status in ('approved', 'rejected') then
    return new;
  end if;

  raise exception 'You are not allowed to modify these outpass fields';
end;
$$;

drop trigger if exists validate_outpass_update_scope on public.outpass_requests;
create trigger validate_outpass_update_scope
before update on public.outpass_requests
for each row execute function enforce_outpass_update_scope();

-- Helpful indexes for the dashboard and role-scoped lookups.
create index if not exists students_profile_id_idx on public.students(profile_id);
create index if not exists students_guardian_id_idx on public.students(guardian_id);
create index if not exists attendance_student_date_idx on public.attendance(student_id, date desc);
create index if not exists fee_invoices_student_status_idx on public.fee_invoices(student_id, status);
create index if not exists outpass_student_idx on public.outpass_requests(student_id);
