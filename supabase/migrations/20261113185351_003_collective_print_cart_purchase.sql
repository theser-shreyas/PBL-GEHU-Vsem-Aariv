/*
# Add collective print-cart checkout

## Overview
Adds one atomic checkout function for the Print & Stationery module. Students can
add multiple catalog items to a cart and submit them together as one purchase.

## New database behavior
- `collective_purchase_print_cart` accepts a student ID and a JSON cart of items.
- The function locks the wallet row, validates every catalog code and quantity,
  calculates prices from the server-side catalog, checks the combined balance,
  deducts the combined amount once, inserts one `print_jobs` row per cart line,
  and writes one audit entry.
- If any line is invalid or the wallet cannot cover the complete cart, no item is
  deducted and no partial jobs are created.

## Security
- The function runs as SECURITY DEFINER with a fixed `search_path`.
- Public and anon execution are revoked, then execution is granted only to the
  roles used by this no-login frontend (`anon`, `authenticated`).
- Existing tables and existing data are unchanged.
*/

CREATE OR REPLACE FUNCTION collective_purchase_print_cart(
    p_student_id text,
    p_items jsonb
) RETURNS TABLE(
    purchase_id uuid,
    new_balance integer,
    total_cost integer,
    jobs_created integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_balance integer;
    v_student_name text;
    v_total integer := 0;
    v_jobs integer := 0;
    v_purchase_id uuid := gen_random_uuid();
    v_item jsonb;
    v_code text;
    v_name text;
    v_file_name text;
    v_quantity integer;
    v_unit_price integer;
BEGIN
    IF jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Cart must contain at least one item';
    END IF;

    SELECT wallet_balance, name
    INTO v_balance, v_student_name
    FROM students
    WHERE id = p_student_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student not found: %', p_student_id;
    END IF;

    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        v_code := v_item->>'item_code';
        v_name := COALESCE(NULLIF(v_item->>'item_name', ''), v_code);
        v_file_name := COALESCE(NULLIF(v_item->>'file_name', ''), 'GEHU_Cart_Order.pdf');

        IF COALESCE(v_item->>'quantity', '') !~ '^[0-9]+$' THEN
            RAISE EXCEPTION 'Invalid quantity for cart item %', v_code;
        END IF;
        v_quantity := (v_item->>'quantity')::integer;

        IF v_quantity < 1 OR v_quantity > 500 THEN
            RAISE EXCEPTION 'Quantity must be between 1 and 500 for cart item %', v_code;
        END IF;

        v_unit_price := CASE v_code
            WHEN 'bw' THEN 2
            WHEN 'color' THEN 5
            WHEN 'poster-a4' THEN 25
            WHEN 'poster-a3' THEN 50
            WHEN 'poster-a2' THEN 75
            WHEN 'thesis' THEN 250
            WHEN 'lamination' THEN 30
            WHEN 'transparent-file' THEN 10
            WHEN 'pen-2' THEN 2
            WHEN 'pen-3' THEN 3
            WHEN 'pen-5' THEN 5
            WHEN 'pen-10' THEN 10
            WHEN 'pen-25' THEN 25
            WHEN 'pen-100' THEN 100
            WHEN 'copy-40' THEN 40
            WHEN 'copy-50' THEN 50
            WHEN 'copy-70' THEN 70
            WHEN 'copy-100' THEN 100
            WHEN 'copy-200' THEN 200
            WHEN 'plastic-card' THEN 50
            ELSE NULL
        END;

        IF v_unit_price IS NULL THEN
            RAISE EXCEPTION 'Unsupported catalog item: %', v_code;
        END IF;

        v_total := v_total + (v_unit_price * v_quantity);
    END LOOP;

    IF v_balance < v_total THEN
        RAISE EXCEPTION 'Insufficient wallet balance: current %, required %', v_balance, v_total;
    END IF;

    UPDATE students
    SET wallet_balance = wallet_balance - v_total
    WHERE id = p_student_id;

    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        v_code := v_item->>'item_code';
        v_name := COALESCE(NULLIF(v_item->>'item_name', ''), v_code);
        v_file_name := COALESCE(NULLIF(v_item->>'file_name', ''), 'GEHU_Cart_Order.pdf');
        v_quantity := (v_item->>'quantity')::integer;
        v_unit_price := CASE v_code
            WHEN 'bw' THEN 2 WHEN 'color' THEN 5 WHEN 'poster-a4' THEN 25
            WHEN 'poster-a3' THEN 50 WHEN 'poster-a2' THEN 75 WHEN 'thesis' THEN 250
            WHEN 'lamination' THEN 30 WHEN 'transparent-file' THEN 10 WHEN 'pen-2' THEN 2
            WHEN 'pen-3' THEN 3 WHEN 'pen-5' THEN 5 WHEN 'pen-10' THEN 10
            WHEN 'pen-25' THEN 25 WHEN 'pen-100' THEN 100 WHEN 'copy-40' THEN 40
            WHEN 'copy-50' THEN 50 WHEN 'copy-70' THEN 70 WHEN 'copy-100' THEN 100
            WHEN 'copy-200' THEN 200 WHEN 'plastic-card' THEN 50 ELSE NULL
        END;

        INSERT INTO print_jobs (
            student_id, item_code, item_name, quantity, unit_price,
            total_price, file_name, status
        ) VALUES (
            p_student_id, v_code, v_name, v_quantity, v_unit_price,
            v_quantity * v_unit_price, v_file_name, 'Queued'
        );
        v_jobs := v_jobs + 1;
    END LOOP;

    PERFORM insert_audit_log(
        format('COLLECTIVE_PURCHASE: %s cart items purchased for Rs.%s. New Balance: Rs.%s. Purchase: %s.',
            v_jobs, v_total, v_balance - v_total, v_purchase_id),
        p_student_id,
        'CSE'
    );

    RETURN QUERY SELECT v_purchase_id, v_balance - v_total, v_total, v_jobs;
END;
$$;

REVOKE EXECUTE ON FUNCTION collective_purchase_print_cart(text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION collective_purchase_print_cart(text, jsonb) TO anon, authenticated;
