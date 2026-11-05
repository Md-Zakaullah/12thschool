create type user_role as enum ('admin','principal','teacher','student','parent','warden','accountant');
create table profiles (id uuid primary key references auth.users on delete cascade, full_name text not null, role user_role not null default 'student', phone text, created_at timestamptz default now());
create table classes (id uuid primary key default gen_random_uuid(), name text not null, section text not null);
create table students (id uuid primary key default gen_random_uuid(), profile_id uuid references profiles(id), admission_no text unique not null, class_id uuid references classes(id), roll_no int, dob date, guardian_id uuid references profiles(id), is_hosteller boolean default false);
create table attendance (id uuid primary key default gen_random_uuid(), student_id uuid references students(id) on delete cascade, date date not null, status text check (status in ('present','absent','late','leave')), marked_by uuid references profiles(id), unique(student_id,date));
create table fee_invoices (id uuid primary key default gen_random_uuid(), student_id uuid references students(id), title text, amount numeric(10,2), due_date date, status text default 'pending');
create table hostels (id uuid primary key default gen_random_uuid(), name text, gender text);
create table rooms (id uuid primary key default gen_random_uuid(), hostel_id uuid references hostels(id), room_no text, floor int, capacity int);
create table beds (id uuid primary key default gen_random_uuid(), room_id uuid references rooms(id), bed_no text, student_id uuid references students(id) unique);
create table outpass_requests (id uuid primary key default gen_random_uuid(), student_id uuid references students(id), reason text, from_ts timestamptz, to_ts timestamptz, parent_status text default 'pending', warden_status text default 'pending');

create function current_role_name() returns user_role language sql stable security definer as $$ select role from profiles where id = auth.uid() $$;

create function handle_new_user() returns trigger language plpgsql security definer as $$
begin insert into profiles(id, full_name) values (new.id, coalesce(new.raw_user_meta_data->>'full_name','New user')); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

alter table profiles enable row level security;
alter table students enable row level security;
alter table attendance enable row level security;
alter table fee_invoices enable row level security;
alter table beds enable row level security;

create policy "own profile" on profiles for select using (id = auth.uid() or current_role_name() in ('admin','principal'));
create policy "staff all students" on students for all using (current_role_name() in ('admin','principal','teacher','warden','accountant'));
create policy "student/parent see own" on students for select using (profile_id = auth.uid() or guardian_id = auth.uid());
create policy "staff attendance" on attendance for all using (current_role_name() in ('admin','principal','teacher'));
create policy "own attendance" on attendance for select using (student_id in (select id from students where profile_id = auth.uid() or guardian_id = auth.uid()));
create policy "accounts fees" on fee_invoices for all using (current_role_name() in ('admin','accountant'));
create policy "own fees" on fee_invoices for select using (student_id in (select id from students where profile_id = auth.uid() or guardian_id = auth.uid()));
create policy "warden beds" on beds for all using (current_role_name() in ('admin','warden'));

-- FIRST ADMIN: signup ke baad ye chalao (email badal do)
-- update profiles set role='admin' where id = (select id from auth.users where email='you@school.com');
