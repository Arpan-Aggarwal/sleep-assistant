from firebase.auth import FirebaseAuth

auth = FirebaseAuth()

# ─── Test 1: Sign Up ──────────────────────────────────────
print("=== Test 1: Sign Up ===")
result = auth.sign_up(
    email="testuser@sleepapp.com",
    password="test123456"
)
print(f"Success: {result['success']}")
if result['success']:
    print(f"User ID: {result['user_id']}")
else:
    print(f"Error: {result['error']}")
print()

# ─── Test 2: Is Logged In ─────────────────────────────────
print("=== Test 2: Is Logged In ===")
print(f"Logged in: {auth.is_logged_in()}")  # Expected: True
print(f"User ID: {auth.get_user_id()}")
print(f"Email: {auth.get_user_email()}")
print()

# ─── Test 3: Sign Out ─────────────────────────────────────
print("=== Test 3: Sign Out ===")
auth.sign_out()
print(f"Logged in after sign out: {auth.is_logged_in()}")  # Expected: False
print()

# ─── Test 4: Sign In ──────────────────────────────────────
print("=== Test 4: Sign In ===")
result = auth.sign_in(
    email="testuser@sleepapp.com",
    password="test123456"
)
print(f"Success: {result['success']}")
if result['success']:
    print(f"User ID: {result['user_id']}")
print()

# ─── Test 5: Wrong Password ───────────────────────────────
print("=== Test 5: Wrong Password ===")
result = auth.sign_in(
    email="testuser@sleepapp.com",
    password="wrongpassword"
)
print(f"Success: {result['success']}")
print(f"Error: {result['error']}")  # Expected: Incorrect password
print()

# ─── Test 6: Duplicate Sign Up ────────────────────────────
print("=== Test 6: Duplicate Email ===")
result = auth.sign_up(
    email="testuser@sleepapp.com",
    password="test123456"
)
print(f"Success: {result['success']}")
print(f"Error: {result['error']}")  # Expected: already registered