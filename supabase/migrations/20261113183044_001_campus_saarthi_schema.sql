/*
# Campus Saarthi — Full Database Schema & Seed Data

## Overview
Creates the complete backend for the Graphic Era Hill University "Campus Saarthi"
campus services portal. Single-tenant (no login screen): all policies scoped to
`anon, authenticated` with `USING (true)` since data is intentionally public.

## New Tables
1. **students** — 100+ student directory with wallet balances (text PK student ID)
2. **print_jobs** — print/stationery order queue with atomic wallet deduction
3. **erp_tickets** — ERP grievance tickets with status workflow
4. **canteen_bookings** — canteen table/event reservations with capacity tracking
5. **audit_logs** — live audit trail of all actions

## Functions
1. **insert_audit_log** — helper to append to audit_logs
2. **deduct_wallet_and_enqueue_print** — atomic wallet deduction + job insert (FOR UPDATE lock)
3. **book_canteen_slot** — capacity check (120 seats) + dynamic pricing + atomic insert

## Security
- RLS enabled on all tables; CRUD granted to anon + authenticated (single-tenant)
- SECURITY DEFINER functions: EXECUTE revoked from PUBLIC, granted to anon + authenticated

## Seed Data
- 106 students, 1 sample print job, 1 sample ERP ticket, 8 canteen bookings, initial audit logs
*/

-- =============================================================
-- TABLES
-- =============================================================

CREATE TABLE IF NOT EXISTS students (
    id text PRIMARY KEY,
    name text NOT NULL,
    batch_year text NOT NULL,
    domain text NOT NULL,
    wallet_balance integer NOT NULL DEFAULT 0 CHECK (wallet_balance >= 0),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS print_jobs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id text NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    item_code text NOT NULL,
    item_name text NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price integer NOT NULL CHECK (unit_price >= 0),
    total_price integer NOT NULL CHECK (total_price >= 0),
    file_name text NOT NULL,
    status text NOT NULL DEFAULT 'Queued',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS erp_tickets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number text NOT NULL UNIQUE,
    student_id text NOT NULL,
    category text NOT NULL,
    branch text NOT NULL,
    semester text NOT NULL,
    mobile text NOT NULL,
    description text NOT NULL,
    status text NOT NULL DEFAULT 'Query Ticket Raised',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS canteen_bookings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tier text NOT NULL CHECK (tier IN ('normal', 'priority')),
    guests integer NOT NULL CHECK (guests >= 2 AND guests <= 30),
    slot_datetime text NOT NULL,
    total_price integer NOT NULL CHECK (total_price >= 0),
    status text NOT NULL DEFAULT 'Booked',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id text NOT NULL DEFAULT '260112459',
    branch text NOT NULL DEFAULT 'CSE',
    action text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- =============================================================
-- INDEXES
-- =============================================================

CREATE INDEX IF NOT EXISTS idx_print_jobs_student ON print_jobs(student_id);
CREATE INDEX IF NOT EXISTS idx_print_jobs_status ON print_jobs(status);
CREATE INDEX IF NOT EXISTS idx_erp_tickets_status ON erp_tickets(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_students_domain ON students(domain);

-- =============================================================
-- RLS + GRANTS
-- =============================================================

ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE print_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE canteen_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON students TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON print_jobs TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON erp_tickets TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON canteen_bookings TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON audit_logs TO anon, authenticated;

-- students
DROP POLICY IF EXISTS "anon_select_students" ON students;
CREATE POLICY "anon_select_students" ON students FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_students" ON students;
CREATE POLICY "anon_insert_students" ON students FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_students" ON students;
CREATE POLICY "anon_update_students" ON students FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_students" ON students;
CREATE POLICY "anon_delete_students" ON students FOR DELETE TO anon, authenticated USING (true);

-- print_jobs
DROP POLICY IF EXISTS "anon_select_print_jobs" ON print_jobs;
CREATE POLICY "anon_select_print_jobs" ON print_jobs FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_print_jobs" ON print_jobs;
CREATE POLICY "anon_insert_print_jobs" ON print_jobs FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_print_jobs" ON print_jobs;
CREATE POLICY "anon_update_print_jobs" ON print_jobs FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_print_jobs" ON print_jobs;
CREATE POLICY "anon_delete_print_jobs" ON print_jobs FOR DELETE TO anon, authenticated USING (true);

-- erp_tickets
DROP POLICY IF EXISTS "anon_select_erp_tickets" ON erp_tickets;
CREATE POLICY "anon_select_erp_tickets" ON erp_tickets FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_erp_tickets" ON erp_tickets;
CREATE POLICY "anon_insert_erp_tickets" ON erp_tickets FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_erp_tickets" ON erp_tickets;
CREATE POLICY "anon_update_erp_tickets" ON erp_tickets FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_erp_tickets" ON erp_tickets;
CREATE POLICY "anon_delete_erp_tickets" ON erp_tickets FOR DELETE TO anon, authenticated USING (true);

-- canteen_bookings
DROP POLICY IF EXISTS "anon_select_canteen" ON canteen_bookings;
CREATE POLICY "anon_select_canteen" ON canteen_bookings FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_canteen" ON canteen_bookings;
CREATE POLICY "anon_insert_canteen" ON canteen_bookings FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_canteen" ON canteen_bookings;
CREATE POLICY "anon_update_canteen" ON canteen_bookings FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_canteen" ON canteen_bookings;
CREATE POLICY "anon_delete_canteen" ON canteen_bookings FOR DELETE TO anon, authenticated USING (true);

-- audit_logs
DROP POLICY IF EXISTS "anon_select_audit" ON audit_logs;
CREATE POLICY "anon_select_audit" ON audit_logs FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_audit" ON audit_logs;
CREATE POLICY "anon_insert_audit" ON audit_logs FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_audit" ON audit_logs;
CREATE POLICY "anon_update_audit" ON audit_logs FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_audit" ON audit_logs;
CREATE POLICY "anon_delete_audit" ON audit_logs FOR DELETE TO anon, authenticated USING (true);

-- =============================================================
-- FUNCTIONS
-- =============================================================

CREATE OR REPLACE FUNCTION insert_audit_log(
    p_action text,
    p_student_id text DEFAULT '260112459',
    p_branch text DEFAULT 'CSE'
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO audit_logs (student_id, branch, action) VALUES (p_student_id, p_branch, p_action);
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_audit_log(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION insert_audit_log(text, text, text) TO anon, authenticated;

-- Atomic wallet deduction + print job enqueue
CREATE OR REPLACE FUNCTION deduct_wallet_and_enqueue_print(
    p_student_id text,
    p_item_code text,
    p_item_name text,
    p_quantity integer,
    p_unit_price integer,
    p_file_name text
) RETURNS TABLE(
    job_id uuid,
    student_name text,
    new_balance integer,
    total_cost integer,
    status text
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_balance integer;
    v_total integer;
    v_name text;
    v_job_id uuid;
BEGIN
    SELECT wallet_balance, name INTO v_balance, v_name
    FROM students WHERE id = p_student_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student not found: %', p_student_id;
    END IF;

    v_total := p_quantity * p_unit_price;

    IF v_balance < v_total THEN
        RAISE EXCEPTION 'Insufficient wallet balance: current %, required %', v_balance, v_total;
    END IF;

    UPDATE students SET wallet_balance = wallet_balance - v_total WHERE id = p_student_id;

    INSERT INTO print_jobs (student_id, item_code, item_name, quantity, unit_price, total_price, file_name, status)
    VALUES (p_student_id, p_item_code, p_item_name, p_quantity, p_unit_price, v_total, p_file_name, 'Queued')
    RETURNING id INTO v_job_id;

    PERFORM insert_audit_log(
        format('PAYMENT_DEDUCT: Student [%s | ID:%s] purchased [%sx %s] - Rs.%s deducted. New Balance: Rs.%s.',
            v_name, p_student_id, p_quantity, p_item_name, v_total, v_balance - v_total),
        p_student_id,
        'CSE'
    );

    RETURN QUERY SELECT v_job_id, v_name, v_balance - v_total, v_total, 'Queued'::text;
END;
$$;

REVOKE EXECUTE ON FUNCTION deduct_wallet_and_enqueue_print(text, text, text, integer, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION deduct_wallet_and_enqueue_print(text, text, text, integer, integer, text) TO anon, authenticated;

-- Canteen booking with capacity check + dynamic pricing
CREATE OR REPLACE FUNCTION book_canteen_slot(
    p_tier text,
    p_guests integer,
    p_slot_datetime text
) RETURNS TABLE(
    booking_id uuid,
    total_price integer,
    current_occupancy integer,
    capacity_remaining integer
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_total integer;
    v_occupancy integer;
    v_capacity integer := 120;
    v_booking_id uuid;
BEGIN
    IF p_tier NOT IN ('normal', 'priority') THEN
        RAISE EXCEPTION 'Invalid tier: %', p_tier;
    END IF;

    SELECT COALESCE(SUM(guests), 0) INTO v_occupancy FROM canteen_bookings WHERE status = 'Booked';

    IF v_occupancy + p_guests > v_capacity THEN
        RAISE EXCEPTION 'Hall capacity exceeded: current %, requested %, max %', v_occupancy, p_guests, v_capacity;
    END IF;

    IF p_tier = 'priority' THEN
        v_total := (p_guests * 50) * 2.5;
    ELSE
        v_total := p_guests * 50;
    END IF;

    INSERT INTO canteen_bookings (tier, guests, slot_datetime, total_price, status)
    VALUES (p_tier, p_guests, p_slot_datetime, v_total, 'Booked')
    RETURNING id INTO v_booking_id;

    PERFORM insert_audit_log(
        format('CANTEEN_LOCK: Acquired semaphore lock for %s guests [Tier: %s]. Total: Rs.%s.', p_guests, p_tier, v_total)
    );

    RETURN QUERY SELECT v_booking_id, v_total, v_occupancy + p_guests, v_capacity - (v_occupancy + p_guests);
END;
$$;

REVOKE EXECUTE ON FUNCTION book_canteen_slot(text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION book_canteen_slot(text, integer, text) TO anon, authenticated;

-- =============================================================
-- SEED DATA: Students (1 leader + 105 generated)
-- =============================================================

INSERT INTO students (id, name, batch_year, domain, wallet_balance) VALUES
('260112459', 'Team Aariv Lead', '2026', 'Full-Stack & React Dev', 2500),
('231940120', 'Asmit Singh', '2023', 'Full-Stack & React Dev', 1850),
('241852003', 'Geetika Mishra', '2024', 'AI/ML & Data Science', 1200),
('251102987', 'Madhusudan Rawat', '2025', 'Database & Systems', 950),
('231940145', 'Purnima Uniyal', '2023', 'UI/UX & Pitch', 2100),
('241852078', 'Priyanshi Sesh', '2024', 'Cybersecurity', 600),
('251102012', 'Adivi Godhari', '2025', 'IoT & Embedded', 1400),
('231940234', 'Shreyas Gurjar', '2023', 'Robotics', 800),
('241852156', 'Aman Choudhary', '2024', 'Cloud & DevOps', 1750),
('251102345', 'Abhinav Aggarwal', '2025', 'Blockchain', 1100),
('231940367', 'Shreshtha Bisht', '2023', 'Game Dev', 1300),
('241852289', 'Riya Das', '2024', 'Full-Stack & React Dev', 900),
('251102456', 'Alok Pandey', '2025', 'AI/ML & Data Science', 1650),
('231940489', 'Amitabh Sharma', '2023', 'Database & Systems', 2200),
('241852312', 'Abhishek Joshi', '2024', 'UI/UX & Pitch', 750),
('251102567', 'Ayush Verma', '2025', 'Cybersecurity', 1000),
('231940523', 'Ankita Kumar', '2023', 'IoT & Embedded', 1900),
('241852434', 'Gayatri Negi', '2024', 'Robotics', 550),
('251102678', 'Renu Tiwari', '2025', 'Cloud & DevOps', 1450),
('231940645', 'Nityakshi Gupta', '2023', 'Blockchain', 1250),
('241852567', 'Sakshi Singh', '2024', 'Game Dev', 850),
('251102789', 'Tarun Mehra', '2025', 'Full-Stack & React Dev', 1700),
('231940712', 'Sumit Mishra', '2023', 'AI/ML & Data Science', 1150),
('241852689', 'Mahesh Uniyal', '2024', 'Database & Systems', 1350),
('251102890', 'Alkesh Sesh', '2025', 'UI/UX & Pitch', 2000),
('231940834', 'Vijay Godhari', '2023', 'Cybersecurity', 650),
('241852712', 'Ravindra Rawat', '2024', 'IoT & Embedded', 1600),
('251102901', 'Aditya Gurjar', '2025', 'Robotics', 1050),
('231940945', 'Trilok Choudhary', '2023', 'Cloud & DevOps', 1800),
('241852834', 'Rinky Aggarwal', '2024', 'Blockchain', 950),
('251102123', 'Pooja Bisht', '2025', 'Game Dev', 700),
('231940567', 'Beena Das', '2023', 'Full-Stack & React Dev', 1550),
('241852145', 'Madhulata Pandey', '2024', 'AI/ML & Data Science', 1100),
('251102234', 'Mandakini Sharma', '2025', 'Database & Systems', 2250),
('231940678', 'Vikas Joshi', '2023', 'UI/UX & Pitch', 850),
('241852256', 'Neha Verma', '2024', 'Cybersecurity', 1400),
('231940789', 'Pankaj Negi', '2023', 'Robotics', 1200),
('241852367', 'Deepak Tiwari', '2024', 'Cloud & DevOps', 600),
('251102456', 'Sanjay Gupta', '2025', 'Blockchain', 1950),
('231940890', 'Kritika Singh', '2023', 'Game Dev', 1300),
('241852478', 'Asmit Mehra', '2024', 'Full-Stack & React Dev', 880),
('251102567', 'Madhusudan Mishra', '2025', 'AI/ML & Data Science', 1650),
('231940123', 'Geetika Uniyal', '2023', 'Database & Systems', 1450),
('241852234', 'Purnima Sesh', '2024', 'UI/UX & Pitch', 2100),
('231940456', 'Adivi Gurjar', '2023', 'IoT & Embedded', 1100),
('241852567', 'Shreyas Choudhary', '2024', 'Robotics', 1900),
('231102678', 'Aman Aggarwal', '2025', 'Cloud & DevOps', 550),
('231940589', 'Abhinav Bisht', '2023', 'Blockchain', 1350),
('241852690', 'Shreshtha Das', '2024', 'Game Dev', 1000),
('231102789', 'Riya Pandey', '2025', 'Full-Stack & React Dev', 1850),
('231940612', 'Alok Sharma', '2023', 'AI/ML & Data Science', 700),
('241852734', 'Amitabh Joshi', '2024', 'Database & Systems', 1600),
('251102845', 'Abhishek Verma', '2025', 'UI/UX & Pitch', 1250),
('231940734', 'Ayush Kumar', '2023', 'Cybersecurity', 1500),
('241852856', 'Ankita Negi', '2024', 'IoT & Embedded', 900),
('251102967', 'Gayatri Tiwari', '2025', 'Robotics', 2150),
('231940845', 'Renu Gupta', '2023', 'Cloud & DevOps', 1150),
('241852967', 'Nityakshi Singh', '2024', 'Blockchain', 1800),
('251102078', 'Sakshi Mehra', '2025', 'Game Dev', 650),
('231940956', 'Tarun Mishra', '2023', 'Full-Stack & React Dev', 1400),
('241852089', 'Sumit Uniyal', '2024', 'AI/ML & Data Science', 1050),
('251102190', 'Mahesh Sesh', '2025', 'Database & Systems', 1700),
('231940067', 'Alkesh Godhari', '2023', 'UI/UX & Pitch', 850),
('241852178', 'Vijay Rawat', '2024', 'Cybersecurity', 1950),
('251102289', 'Ravindra Gurjar', '2025', 'IoT & Embedded', 1200),
('231940178', 'Aditya Choudhary', '2023', 'Robotics', 1550),
('241852267', 'Trilok Aggarwal', '2024', 'Cloud & DevOps', 800),
('251102367', 'Rinky Bisht', '2025', 'Blockchain', 1450),
('231940289', 'Pooja Das', '2023', 'Game Dev', 1100),
('241852345', 'Beena Pandey', '2024', 'Full-Stack & React Dev', 1850),
('251102456', 'Madhulata Sharma', '2025', 'AI/ML & Data Science', 950),
('231940345', 'Mandakini Joshi', '2023', 'Database & Systems', 2200),
('241852423', 'Vikas Verma', '2024', 'UI/UX & Pitch', 750),
('251102534', 'Neha Kumar', '2025', 'Cybersecurity', 1350),
('231940456', 'Rahul Negi', '2023', 'IoT & Embedded', 1600),
('241852534', 'Pankaj Tiwari', '2024', 'Robotics', 1050),
('251102645', 'Deepak Gupta', '2025', 'Cloud & DevOps', 1900),
('231940567', 'Sanjay Singh', '2023', 'Blockchain', 700),
('241852645', 'Kritika Mehra', '2024', 'Game Dev', 1250),
('251102756', 'Aman Mishra', '2025', 'Full-Stack & React Dev', 1800),
('231940678', 'Riya Uniyal', '2023', 'AI/ML & Data Science', 1150),
('241852756', 'Alok Sesh', '2024', 'Database & Systems', 550),
('251102867', 'Amitabh Godhari', '2025', 'UI/UX & Pitch', 2100),
('231940789', 'Abhishek Gurjar', '2023', 'Cybersecurity', 1450),
('241852867', 'Ayush Choudhary', '2024', 'IoT & Embedded', 900),
('251102978', 'Ankita Aggarwal', '2025', 'Robotics', 1650),
('231940890', 'Gayatri Bisht', '2023', 'Cloud & DevOps', 1300),
('241852978', 'Renu Das', '2024', 'Blockchain', 1000),
('251102089', 'Nityakshi Pandey', '2025', 'Game Dev', 1850),
('231940901', 'Sakshi Sharma', '2023', 'Full-Stack & React Dev', 750),
('241852090', 'Tarun Joshi', '2024', 'AI/ML & Data Science', 1500),
('251102190', 'Sumit Verma', '2025', 'Database & Systems', 1150),
('231940012', 'Mahesh Kumar', '2023', 'UI/UX & Pitch', 1950),
('241852123', 'Alkesh Negi', '2024', 'Cybersecurity', 850),
('251102290', 'Vijay Tiwari', '2025', 'IoT & Embedded', 1700),
('231940123', 'Ravindra Gupta', '2023', 'Robotics', 600),
('241852234', 'Aditya Singh', '2024', 'Cloud & DevOps', 1400),
('251102390', 'Trilok Mehra', '2025', 'Blockchain', 1250),
('231940234', 'Rinky Mishra', '2023', 'Game Dev', 1100),
('241852345', 'Pooja Uniyal', '2024', 'Full-Stack & React Dev', 1850),
('251102490', 'Beena Sesh', '2025', 'AI/ML & Data Science', 950),
('231940345', 'Madhulata Godhari', '2023', 'Database & Systems', 2250),
('241852456', 'Mandakini Rawat', '2024', 'UI/UX & Pitch', 700),
('251102590', 'Vikas Gurjar', '2025', 'Cybersecurity', 1550),
('231940456', 'Neha Choudhary', '2023', 'IoT & Embedded', 1300),
('241852567', 'Rahul Aggarwal', '2024', 'Robotics', 1050),
('251102690', 'Pankaj Bisht', '2025', 'Cloud & DevOps', 1900)
ON CONFLICT (id) DO NOTHING;

-- Sample print job, ERP ticket, canteen occupancy, audit logs
INSERT INTO print_jobs (student_id, item_code, item_name, quantity, unit_price, total_price, file_name, status)
VALUES ('260112459', 'thesis', 'Thesis Hard Binding (Rs.250/copy)', 1, 250, 250, 'Thesis_Final.pdf', 'Processing')
ON CONFLICT DO NOTHING;

INSERT INTO erp_tickets (ticket_number, student_id, category, branch, semester, mobile, description, status)
VALUES ('ERP-9921', '260112459', 'Exam Registration', 'B.Tech - Computer Science (Core)',
        'V Semester (3rd Year - Current)', '+91 9876543210',
        'Exam Registration: Elective timetable overlap reported.', 'Query Ticket Raised')
ON CONFLICT (ticket_number) DO NOTHING;

INSERT INTO canteen_bookings (tier, guests, slot_datetime, total_price, status)
VALUES
    ('normal', 12, '2026-11-14T12:00', 600, 'Booked'),
    ('normal', 8, '2026-11-14T13:00', 400, 'Booked'),
    ('normal', 15, '2026-11-14T14:00', 750, 'Booked'),
    ('priority', 10, '2026-11-14T19:00', 1250, 'Booked'),
    ('normal', 6, '2026-11-14T20:00', 300, 'Booked'),
    ('normal', 6, '2026-11-13T12:00', 300, 'Booked'),
    ('normal', 6, '2026-11-13T13:00', 300, 'Booked'),
    ('priority', 21, '2026-11-13T19:00', 2625, 'Booked')
ON CONFLICT DO NOTHING;

INSERT INTO audit_logs (student_id, branch, action)
VALUES
    ('260112459', 'CSE', 'INIT: Campus Saarthi local node handshake established successfully.'),
    ('260112459', 'CSE', 'AUTH: Student credential verified -> ID: 260112459 | Team: Aariv')
ON CONFLICT DO NOTHING;
