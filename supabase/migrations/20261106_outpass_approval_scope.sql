-- Apply this migration to an existing Supabase database after the original schema.sql.
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

create index if not exists students_profile_id_idx on public.students(profile_id);
create index if not exists students_guardian_id_idx on public.students(guardian_id);
create index if not exists attendance_student_date_idx on public.attendance(student_id, date desc);
create index if not exists fee_invoices_student_status_idx on public.fee_invoices(student_id, status);
create index if not exists outpass_student_idx on public.outpass_requests(student_id);
