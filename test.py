# test_classifier.py
from core.classifier import SleepClassifier

clf = SleepClassifier()
print(f"Model loaded: {clf.is_model_loaded()}")
print()

print("=== Test 1: High risk — too much screen time ===")
result = clf.classify({
    'total_screen_time': 55,
    'unlock_count': 14,
    'longest_session': 30,
    'hour_of_first_use': 23,
    'app_category': 2
})
print(f"Result: {result}")  # Expected: High
print()

print("=== Test 2: High risk — many unlocks late at night ===")
result = clf.classify({
    'total_screen_time': 18,
    'unlock_count': 12,
    'longest_session': 5,
    'hour_of_first_use': 23,
    'app_category': 2
})
print(f"Result: {result}")  # Expected: High
print()

print("=== Test 3: Medium risk ===")
result = clf.classify({
    'total_screen_time': 25,
    'unlock_count': 6,
    'longest_session': 12,
    'hour_of_first_use': 22,
    'app_category': 0
})
print(f"Result: {result}")  # Expected: Medium
print()

print("=== Test 4: Low risk ===")
result = clf.classify({
    'total_screen_time': 8,
    'unlock_count': 2,
    'longest_session': 6,
    'hour_of_first_use': 22,
    'app_category': 1
})
print(f"Result: {result}")  # Expected: Low
print()

print("=== Test 5: Missing data (edge case) ===")
result = clf.classify({})
print(f"Result: {result}")