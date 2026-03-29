# screens/onboarding.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import threading
from kivy.uix.screenmanager import Screen
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.graphics import Color, Rectangle
from kivy.clock import Clock


class OnboardingScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.step      = 1
        self.user_data = {}
        self.is_signin = False
        self._build_ui()

    # ─── BACKGROUND ──────────────────────────────────────────

    def _set_background(self):
        with self.canvas.before:
            Color(0.04, 0.055, 0.1, 1)
            self.bg_rect = Rectangle(
                size=self.size, pos=self.pos
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
            font_size='12sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.93}
        )

        # ── Question label
        self.question_label = Label(
            text='Create your account',
            font_size='22sp',
            bold=True,
            color=(0.85, 0.88, 0.95, 1),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.82}
        )

        # ── Subtitle
        self.subtitle_label = Label(
            text='Your data stays private and secure',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.6),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.74}
        )

        # ── Input 1 — email
        self.input1 = TextInput(
            hint_text='Email address',
            multiline=False,
            size_hint=(0.78, None),
            height=48,
            pos_hint={'center_x': 0.5, 'center_y': 0.62},
            background_color=(0.11, 0.14, 0.24, 1),
            foreground_color=(0.85, 0.88, 0.95, 1),
            hint_text_color=(0.48, 0.56, 0.75, 0.4),
            cursor_color=(0.48, 0.56, 0.75, 1),
            padding=[14, 14]
        )

        # ── Input 2 — password
        self.input2 = TextInput(
            hint_text='Password (min 6 characters)',
            password=True,
            multiline=False,
            size_hint=(0.78, None),
            height=48,
            pos_hint={'center_x': 0.5, 'center_y': 0.51},
            background_color=(0.11, 0.14, 0.24, 1),
            foreground_color=(0.85, 0.88, 0.95, 1),
            hint_text_color=(0.48, 0.56, 0.75, 0.4),
            cursor_color=(0.48, 0.56, 0.75, 1),
            padding=[14, 14]
        )

        # ── Error label
        self.error_label = Label(
            text='',
            font_size='12sp',
            color=(0.9, 0.4, 0.4, 1),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.42}
        )

        # ── Next button
        self.next_btn = Button(
            text='Continue',
            font_size='15sp',
            size_hint=(0.78, None),
            height=50,
            pos_hint={'center_x': 0.5, 'center_y': 0.33},
            background_color=(0.2, 0.3, 0.55, 1),
            background_normal='',
            color=(1, 1, 1, 1)
        )
        self.next_btn.bind(on_press=self._on_next)

        # ── Toggle sign in / sign up button
        self.toggle_btn = Button(
            text='Already have an account?  Sign In',
            font_size='13sp',
            size_hint=(0.78, None),
            height=40,
            pos_hint={'center_x': 0.5, 'center_y': 0.22},
            background_color=(0, 0, 0, 0),
            background_normal='',
            color=(0.5, 0.65, 0.9, 1)
        )
        self.toggle_btn.bind(on_press=self._toggle_mode)

        # ── Mode buttons (step 4 only, hidden by default)
        self.silent_btn = Button(
            text='Silent Mode\nOnly a soft notification if needed',
            font_size='14sp',
            halign='center',
            size_hint=(0.78, None),
            height=70,
            pos_hint={'center_x': 0.5, 'center_y': 0.62},
            background_color=(0.11, 0.14, 0.24, 1),
            background_normal='',
            color=(0.85, 0.88, 0.95, 0.9),
            opacity=0,
            disabled=True
        )
        self.silent_btn.bind(
            on_press=lambda x: self._select_mode('silent')
        )

        self.active_btn = Button(
            text='Active Mode\nOffer support tools more often',
            font_size='14sp',
            halign='center',
            size_hint=(0.78, None),
            height=70,
            pos_hint={'center_x': 0.5, 'center_y': 0.48},
            background_color=(0.11, 0.14, 0.24, 1),
            background_normal='',
            color=(0.85, 0.88, 0.95, 0.9),
            opacity=0,
            disabled=True
        )
        self.active_btn.bind(
            on_press=lambda x: self._select_mode('active')
        )

        # ── Add all widgets
        self.layout.add_widget(self.step_label)
        self.layout.add_widget(self.question_label)
        self.layout.add_widget(self.subtitle_label)
        self.layout.add_widget(self.error_label)
        self.layout.add_widget(self.silent_btn)
        self.layout.add_widget(self.active_btn)
        self.layout.add_widget(self.next_btn)
        self.layout.add_widget(self.toggle_btn)
        self.layout.add_widget(self.input2)   # inputs added last
        self.layout.add_widget(self.input1)

        self.add_widget(self.layout)

    # ─── TOGGLE SIGN IN / SIGN UP ────────────────────────────

    def _toggle_mode(self, instance):
        """
        Switch between sign up and sign in.
        Only visible on step 1.
        Resets form completely.
        """
        self.is_signin     = not self.is_signin
        self.input1.text   = ''
        self.input2.text   = ''
        self.error_label.text = ''

        if self.is_signin:
            self.step_label.text      = 'Welcome back'
            self.question_label.text  = 'Sign In'
            self.subtitle_label.text  = 'Good to see you again'
            self.input2.hint_text     = 'Password'
            self.next_btn.text        = 'Sign In'
            self.toggle_btn.text      = 'New here?  Create an Account'
        else:
            self.step_label.text      = 'Step 1 of 4'
            self.question_label.text  = 'Create your account'
            self.subtitle_label.text  = 'Your data stays private and secure'
            self.input2.hint_text     = 'Password (min 6 characters)'
            self.next_btn.text        = 'Continue'
            self.toggle_btn.text      = 'Already have an account?  Sign In'

    # ─── NEXT BUTTON ─────────────────────────────────────────

    def _on_next(self, instance):
        self.error_label.text = ''

        if self.step == 1:
            if self.is_signin:
                self._handle_signin()
            else:
                self._handle_signup()
        elif self.step == 2:
            self._handle_step2()
        elif self.step == 3:
            self._handle_step3()

    # ─── SIGN UP ─────────────────────────────────────────────

    def _handle_signup(self):
        email    = self.input1.text.strip()
        password = self.input2.text.strip()

        if not email or not password:
            self.error_label.text = 'Please fill in both fields'
            return
        if len(password) < 6:
            self.error_label.text = 'Password must be at least 6 characters'
            return

        self.next_btn.disabled = True
        self.next_btn.text     = 'Creating account...'

        def _signup():
            from firebase.auth import FirebaseAuth
            auth   = FirebaseAuth()
            result = auth.sign_up(email=email, password=password)
            Clock.schedule_once(
                lambda dt: self._on_auth_done(result, auth), 0
            )

        threading.Thread(target=_signup, daemon=True).start()

    # ─── SIGN IN ─────────────────────────────────────────────

    def _handle_signin(self):
        email    = self.input1.text.strip()
        password = self.input2.text.strip()

        if not email or not password:
            self.error_label.text = 'Please fill in both fields'
            return

        self.next_btn.disabled = True
        self.next_btn.text     = 'Signing in...'

        def _signin():
            from firebase.auth import FirebaseAuth
            auth   = FirebaseAuth()
            result = auth.sign_in(email=email, password=password)
            Clock.schedule_once(
                lambda dt: self._on_auth_done(result, auth), 0
            )

        threading.Thread(target=_signin, daemon=True).start()

    def _on_auth_done(self, result, auth):
        self.next_btn.disabled = False
        self.next_btn.text     = 'Continue'

        if not result['success']:
            self.error_label.text = result['error']
            return

        self.user_data['user_id'] = result['user_id']
        self.user_data['auth']    = auth

        # Existing user — skip setup and go home
        if self.is_signin:
            self._finish_existing_user(result['user_id'])
        else:
            self._go_to_step2()

    def _finish_existing_user(self, user_id):
        """Sign in user — save user_id locally and go home"""
        def _save():
            from core.queue_manager import QueueManager
            queue = QueueManager()
            prefs = queue.get_prefs()
            prefs['user_id']        = user_id
            prefs['setup_complete'] = True
            queue.save_prefs(prefs)
            Clock.schedule_once(self._go_to_home, 0.5)

        threading.Thread(target=_save, daemon=True).start()

    # ─── STEP 2: SLEEP TIME ──────────────────────────────────

    def _go_to_step2(self):
        self.step = 2

        self.step_label.text      = 'Step 2 of 4'
        self.question_label.text  = 'When do you want to sleep?'
        self.subtitle_label.text  = 'We start watching over you from this time'

        self.input1.hint_text = 'e.g. 11:00 PM'
        self.input1.text      = ''

        self.input2.opacity  = 0
        self.input2.disabled = True

        self.toggle_btn.opacity  = 0
        self.toggle_btn.disabled = True

        self.next_btn.text     = 'Continue'
        self.next_btn.disabled = False

        self.error_label.text = ''

    def _handle_step2(self):
        sleep_time = self.input1.text.strip()
        if not sleep_time:
            self.error_label.text = 'Please enter a time e.g. 11:00 PM'
            return
        self.user_data['sleepGoalTime'] = sleep_time
        self._go_to_step3()

    # ─── STEP 3: WAKE TIME ───────────────────────────────────

    def _go_to_step3(self):
        self.step = 3

        self.step_label.text     = 'Step 3 of 4'
        self.question_label.text = 'When do you wake up?'
        self.subtitle_label.text = 'Your morning report will be ready by then'

        self.input1.hint_text = 'e.g. 6:30 AM'
        self.input1.text      = ''
        self.error_label.text = ''
        self.next_btn.text    = 'Continue'

    def _handle_step3(self):
        wake_time = self.input1.text.strip()
        if not wake_time:
            self.error_label.text = 'Please enter a time e.g. 6:30 AM'
            return
        self.user_data['wakeTime'] = wake_time
        self._go_to_step4()

    # ─── STEP 4: MODE SELECTION ──────────────────────────────

    def _go_to_step4(self):
        self.step = 4

        self.step_label.text     = 'Step 4 of 4'
        self.question_label.text = 'How should I check in with you?'
        self.subtitle_label.text = 'You can change this later'

        # Hide inputs and next button
        self.input1.opacity    = 0
        self.input1.disabled   = True
        self.next_btn.opacity  = 0
        self.next_btn.disabled = True
        self.step_label.opacity = 0

        # Show mode buttons
        self.silent_btn.opacity  = 1
        self.silent_btn.disabled = False
        self.active_btn.opacity  = 1
        self.active_btn.disabled = False

        self.error_label.text = ''

    def _select_mode(self, mode):
        self.user_data['mode'] = mode
        self._save_and_finish()

    # ─── SAVE AND FINISH ─────────────────────────────────────

    def _save_and_finish(self):
        def _save():
            from core.queue_manager import QueueManager
            from firebase.firestore import FirestoreManager

            queue   = QueueManager()
            user_id = self.user_data['user_id']
            fs      = FirestoreManager(user_id, queue)

            profile = {
                'sleepGoalTime':  self.user_data.get('sleepGoalTime'),
                'wakeTime':       self.user_data.get('wakeTime'),
                'mode':           self.user_data.get('mode', 'silent'),
                'user_id':        user_id,
                'setup_complete': True
            }

            fs.save_profile(profile)
            queue.save_prefs(profile)

            Clock.schedule_once(self._go_to_home, 1)

        threading.Thread(target=_save, daemon=True).start()

    # ─── GO HOME ─────────────────────────────────────────────

    def _go_to_home(self, dt=None):
        from datetime import datetime
        hour = datetime.now().hour
        if hour >= 22 or hour < 4:
            self.manager.current = 'home_night'
        else:
            self.manager.current = 'home_day'