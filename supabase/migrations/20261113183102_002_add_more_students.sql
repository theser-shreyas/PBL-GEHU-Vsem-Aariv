/*
# Add additional students to reach 100+ directory

Adds 20 more unique student records to the students table so the
directory exceeds 100 entries as described in the app's UI.
*/

INSERT INTO students (id, name, batch_year, domain, wallet_balance) VALUES
('230111001', 'Arjun Bisht', '2023', 'Full-Stack & React Dev', 1650),
('230111002', 'Vivek Sharma', '2023', 'AI/ML & Data Science', 1200),
('230111003', 'Kavya Negi', '2023', 'Database & Systems', 950),
('230111004', 'Rohit Tiwari', '2023', 'UI/UX & Pitch', 2100),
('230111005', 'Isha Gupta', '2023', 'Cybersecurity', 800),
('230111006', 'Karan Singh', '2023', 'IoT & Embedded', 1450),
('230111007', 'Meera Das', '2023', 'Robotics', 1100),
('230111008', 'Arnav Pandey', '2023', 'Cloud & DevOps', 1900),
('230111009', 'Tanvi Joshi', '2023', 'Blockchain', 750),
('230111010', 'Yash Verma', '2023', 'Game Dev', 1350),
('240111001', 'Diya Kumar', '2024', 'Full-Stack & React Dev', 1850),
('240111002', 'Aryan Mehra', '2024', 'AI/ML & Data Science', 600),
('240111003', 'Sneha Uniyal', '2024', 'Database & Systems', 1550),
('240111004', 'Dev Sesh', '2024', 'UI/UX & Pitch', 1000),
('240111005', 'Anvi Godhari', '2024', 'Cybersecurity', 1250),
('250111001', 'Kiara Rawat', '2025', 'IoT & Embedded', 1750),
('250111002', 'Veer Gurjar', '2025', 'Robotics', 900),
('250111003', 'Myra Choudhary', '2025', 'Cloud & DevOps', 1400),
('250111004', 'Reyansh Aggarwal', '2025', 'Blockchain', 1150),
('250111005', 'Aadhya Bisht', '2025', 'Game Dev', 2000)
ON CONFLICT (id) DO NOTHING;
