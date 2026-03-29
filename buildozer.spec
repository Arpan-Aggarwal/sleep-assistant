[app]
title = Sleep Assistant
package.name = sleepassistant
package.domain = org.sleepapp
source.dir = .
source.include_exts = py,png,jpg,kv,json
source.exclude_dirs = tests,bin,venv,server,cloud_functions,.git,data
version = 1.0

requirements = python3,
    kivy==2.3.0,
    firebase-admin,
    pyrebase4,
    scikit-learn,
    numpy,
    pandas,
    pyjnius,
    android,
    requests

orientation = portrait
fullscreen = 0

android.permissions = INTERNET,
    FOREGROUND_SERVICE,
    PACKAGE_USAGE_STATS,
    POST_NOTIFICATIONS,
    RECEIVE_BOOT_COMPLETED,
    WAKE_LOCK

android.api = 33
android.minapi = 26
android.ndk = 25b
android.sdk = 33
android.accept_sdk_license = True

android.archs = arm64-v8a

services = SleepTrackerService:services/background.py:foreground

[buildozer]
log_level = 2
warn_on_root = 1