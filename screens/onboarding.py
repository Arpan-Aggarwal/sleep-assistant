# screens/onboarding.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.floatlayout import FloatLayout
from kivy.graphics import Color, Rectangle
from kivy.clock import Clock


class OnboardingScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.step        = 1      # tracks which step user is on
        self.user_data   = {}     # collects data across steps
        self._build_ui()

    # ─── BACKGROUND COLOR ────────────────────────────────────

    def _set_background(self):
        with self.canvas.before:
            Color(0.04, 0.055, 0.1, 1)   # deep navy #0A0E1A
            self.bg_rect = Rectangle(
                size=self.size,
                pos=self.pos
            )
        self.bind(size=self._update_bg, pos=self._update_bg)

    def _update_bg(self, *args):
        self.bg_rect.size = self.size
        self.bg_rect.pos  = self.pos

    # ─── BUILD UI ────────────────────────────────────────────

    def _build_ui(self):
        self._set_background()

        self.layout = FloatLayout()

        # ── Step indicator
        self.step_label = Label(
            text='Step 1 of 4',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.6),   # muted lavender
            pos_hint={'center_x': 0.5, 'top': 0.97}
        )

        # ── Main question label
        self.question_label = Label(
            text='Create your account',
            font_size='22sp',
            bold=True,
            color=(0.85, 0.88, 0.95, 1),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.72}
        )

        # ── Subtitle
        self.subtitle_label = Label(
            text='Your data stays private and secure',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.7),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.64}
        )

        # ── Input field 1 (email / time)
        self.input1 = TextInput(
            hint_text='Email address',
            multiline=False,
            size_hint=(0.78, None),
            height=48,
            pos_hint={'center_x': 0.5, 'center_y': 0.52},
            background_color=(0.11, 0.14, 0.24, 1),
            foreground_color=(0.85, 0.88, 0.95, 1),
            hint_text_color=(0.48, 0.56, 0.75, 0.5),
            cursor_color=(0.48, 0.56, 0.75, 1),
            padding=[12, 12]
        )

        # ── Input field 2 (password only on step 1)
        self.input2 = TextInput(
            hint_text='Password (min 6 characters)',
            password=True,
            multiline=False,
            size_hint=(0.78, None),
            height=48,
            pos_hint={'center_x': 0.5, 'center_y': 0.42},
            background_color=(0.11, 0.14, 0.24, 1),
            foreground_color=(0.85, 0.88, 0.95, 1),
            hint_text_color=(0.48, 0.56, 0.75, 0.5),
            cursor_color=(0.48, 0.56, 0.75, 1),
            padding=[12, 12]
        )

        # ── Error label
        self.error_label = Label(
            text='',
            font_size='12sp',
            color=(0.9, 0.4, 0.4, 1),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.34}
        )

        # ── Next button
        self.next_btn = Button(
            text='Continue',
            font_size='16sp',
            size_hint=(0.78, None),
            height=52,
            pos_hint={'center_x': 0.5, 'center_y': 0.24},
            background_color=(0.3, 0.4, 0.7, 1),
            color=(1, 1, 1, 1)
        )
        self.next_btn.bind(on_press=self._on_next)

        # Add everything to layout
        self.layout.add_widget(self.step_label)
        self.layout.add_widget(self.question_label)
        self.layout.add_widget(self.subtitle_label)
        self.layout.add_widget(self.input1)
        self.layout.add_widget(self.input2)
        self.layout.add_widget(self.error_label)
        self.layout.add_widget(self.next_btn)

        self.add_widget(self.layout)

    # ─── STEP NAVIGATION ─────────────────────────────────────

    def _on_next(self, instance):
        """Called when user taps Continue"""
        self.error_label.text = ''

        if self.step == 1:
            self._handle_step1()
        elif self.step == 2:
            self._handle_step2()
        elif self.step == 3:
            self._handle_step3()
        elif self.step == 4:
            self._handle_step4()

    # ─── STEP 1: Email + Password ─────────────────────────────

    def _handle_step1(self):
        email    = self.input1.text.strip()
        password = self.input2.text.strip()

        if not email or not password:
            self.error_label.text = 'Please fill in both fields'
            return

        if len(password) < 6:
            self.error_label.text = 'Password must be at least 6 characters'
            return

        # Disable button while processing
        self.next_btn.disabled = True
        self.next_btn.text     = 'Creating account...'

        # Sign up in background thread
        import threading
        def _signup():
            from firebase.auth import FirebaseAuth
            auth   = FirebaseAuth()
            result = auth.sign_up(email=email, password=password)

            # Update UI on main thread
            Clock.schedule_once(
                lambda dt: self._on_signup_result(result, auth), 0
            )

        threading.Thread(target=_signup, daemon=True).start()

    def _on_signup_result(self, result, auth):
        self.next_btn.disabled = False
        self.next_btn.text     = 'Continue'

        if result['success']:
            self.user_data['user_id'] = result['user_id']
            self.user_data['auth']    = auth
            self._go_to_step2()
        else:
            self.error_label.text = result['error']

    # ─── STEP 2: Sleep Goal Time ──────────────────────────────

    def _go_to_step2(self):
        self.step = 2
        self.step_label.text     = 'Step 2 of 4'
        self.question_label.text = 'When do you want to sleep?'
        self.subtitle_label.text = 'We will start watching over you from this time'
        self.input1.hint_text    = 'e.g. 11:00 PM'
        self.input1.text         = ''
        self.input2.opacity      = 0
        self.input2.disabled     = True

    def _handle_step2(self):
        sleep_time = self.input1.text.strip()
        if not sleep_time:
            self.error_label.text = 'Please enter your sleep goal time'
            return
        self.user_data['sleepGoalTime'] = sleep_time
        self._go_to_step3()

    # ─── STEP 3: Wake Time ────────────────────────────────────

    def _go_to_step3(self):
        self.step = 3
        self.step_label.text     = 'Step 3 of 4'
        self.question_label.text = 'When do you usually wake up?'
        self.subtitle_label.text = 'Your morning report will be ready by then'
        self.input1.hint_text    = 'e.g. 6:30 AM'
        self.input1.text         = ''

    def _handle_step3(self):
        wake_time = self.input1.text.strip()
        if not wake_time:
            self.error_label.text = 'Please enter your wake up time'
            return
        self.user_data['wakeTime'] = wake_time
        self._go_to_step4()

    # ─── STEP 4: Mode Preference ──────────────────────────────

    def _go_to_step4(self):
        self.step = 4
        self.step_label.text     = 'Step 4 of 4'
        self.question_label.text = 'How should I check in with you?'
        self.subtitle_label.text = 'You can change this later'
        self.input1.opacity      = 0
        self.input1.disabled     = True

        # Replace input with two mode buttons
        self.silent_btn = Button(
            text='🌙  Silent Mode\nOnly a soft notification if needed',
            font_size='14sp',
            halign='center',
            size_hint=(0.78, None),
            height=70,
            pos_hint={'center_x': 0.5, 'center_y': 0.55},
            background_color=(0.11, 0.14, 0.24, 1),
            color=(0.85, 0.88, 0.95, 1)
        )
        self.silent_btn.bind(on_press=lambda x: self._select_mode('silent'))

        self.active_btn = Button(
            text='💬  Active Mode\nOffer support tools more often',
            font_size='14sp',
            halign='center',
            size_hint=(0.78, None),
            height=70,
            pos_hint={'center_x': 0.5, 'center_y': 0.42},
            background_color=(0.11, 0.14, 0.24, 1),
            color=(0.85, 0.88, 0.95, 1)
        )
        self.active_btn.bind(on_press=lambda x: self._select_mode('active'))

        self.next_btn.opacity  = 0
        self.next_btn.disabled = True

        self.layout.add_widget(self.silent_btn)
        self.layout.add_widget(self.active_btn)

    def _select_mode(self, mode):
        self.user_data['mode'] = mode
        self._handle_step4()

    def _handle_step4(self):
        """Save everything and move to home screen"""
        self._save_and_finish()

    # ─── SAVE AND FINISH ─────────────────────────────────────

    def _save_and_finish(self):
        """Save profile to Firebase and locally then go to home"""
        import threading
        from core.queue_manager import QueueManager
        from firebase.firestore import FirestoreManager

        def _save():
            queue    = QueueManager()
            user_id  = self.user_data['user_id']
            fs       = FirestoreManager(user_id, queue)

            profile = {
                'sleepGoalTime': self.user_data.get('sleepGoalTime'),
                'wakeTime':      self.user_data.get('wakeTime'),
                'mode':          self.user_data.get('mode', 'silent'),
                'user_id':       user_id,
                'setup_complete': True
            }

            # Save to Firestore
            fs.save_profile(profile)

            # Save locally
            queue.save_prefs(profile)

            # Go to home screen on main thread
            Clock.schedule_once(self._go_to_home, 1)

        threading.Thread(target=_save, daemon=True).start()

    def _go_to_home(self, dt):
        from datetime import datetime
        hour = datetime.now().hour
        if hour >= 22 or hour < 4:
            self.manager.current = 'home_night'
        else:
            self.manager.current = 'home_day'