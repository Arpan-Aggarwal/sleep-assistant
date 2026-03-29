# test_service.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import time
from services.background import start_service

print("Starting background service simulation...")
print("Watch for check logs every 60 seconds")
print("Press Ctrl+C to stop\n")

# Start service
thread = start_service()

# Keep running so we can see output
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\nService stopped.")