# screens/home_day.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from kivy.uix.screenmanager import Screen
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.graphics import Color, Rectangle, RoundedRectangle
from kivy.clock import Clock


class HomeDayScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.session_data = {}
        self._build_ui()

    # ─── BACKGROUND ──────────────────────────────────────────

    def _set_background(self):
        with self.canvas.before:
            Color(0.04, 0.055, 0.1, 1)
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

        # ── Title
        self.title_label = Label(
            text='Good morning',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.93}
        )

        # ── Last night label
        self.last_night_label = Label(
            text='Last night',
            font_size='12sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.86}
        )

        # ── Risk score (big, center)
        self.risk_score_label = Label(
            text='--',
            font_size='42sp',
            bold=True,
            color=(0.85, 0.88, 0.95, 0.9),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.78}
        )

        # ── Risk subtitle
        self.risk_sub_label = Label(
            text='sleep disruption risk',
            font_size='12sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.71}
        )

        # ── Divider line
        self.divider = Widget(
            size_hint=(0.8, None),
            height=1,
            pos_hint={'center_x': 0.5, 'center_y': 0.66}
        )
        with self.divider.canvas:
            Color(0.48, 0.56, 0.75, 0.15)
            Rectangle(
                size=self.divider.size,
                pos=self.divider.pos
            )

        # ── Stats row labels (left side)
        self.stat1_label = Label(
            text='Screen time\n--',
            font_size='13sp',
            color=(0.85, 0.88, 0.95, 0.8),
            halign='center',
            pos_hint={'center_x': 0.2, 'center_y': 0.57}
        )

        self.stat2_label = Label(
            text='Unlocks\n--',
            font_size='13sp',
            color=(0.85, 0.88, 0.95, 0.8),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.57}
        )

        self.stat3_label = Label(
            text='Longest session\n--',
            font_size='13sp',
            color=(0.85, 0.88, 0.95, 0.8),
            halign='center',
            pos_hint={'center_x': 0.8, 'center_y': 0.57}
        )

        # ── Insight card background
        self.insight_bg = Widget(
            size_hint=(0.85, None),
            height=80,
            pos_hint={'center_x': 0.5, 'center_y': 0.41}
        )
        with self.insight_bg.canvas:
            Color(0.11, 0.14, 0.24, 1)
            self.insight_rect = RoundedRectangle(
                size=self.insight_bg.size,
                pos=self.insight_bg.pos,
                radius=[10]
            )
        self.insight_bg.bind(
            size=self._update_insight_bg,
            pos=self._update_insight_bg
        )

        # ── Insight text
        self.insight_label = Label(
            text='Loading your insight...',
            font_size='12sp',
            color=(0.7, 0.78, 0.95, 0.8),
            halign='center',
            text_size=(300, None),
            pos_hint={'center_x': 0.5, 'center_y': 0.41}
        )

        # ── Pattern detected label
        self.pattern_label = Label(
            text='',
            font_size='11sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.30}
        )

        # ── Feedback label
        self.feedback_label = Label(
            text='Did last night feel better?',
            font_size='12sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.21}
        )

        # ── Feedback buttons
        self.yes_btn = Button(
            text='Yes, slept well',
            font_size='13sp',
            size_hint=(0.4, None),
            height=44,
            pos_hint={'center_x': 0.28, 'center_y': 0.13},
            background_color=(0.15, 0.22, 0.38, 1),
            background_normal='',
            color=(0.7, 0.88, 0.75, 1)
        )
        self.yes_btn.bind(on_press=lambda x: self._save_feedback(True))

        self.no_btn = Button(
            text='Not really',
            font_size='13sp',
            size_hint=(0.4, None),
            height=44,
            pos_hint={'center_x': 0.72, 'center_y': 0.13},
            background_color=(0.15, 0.14, 0.24, 1),
            background_normal='',
            color=(0.75, 0.65, 0.78, 1)
        )
        self.no_btn.bind(on_press=lambda x: self._save_feedback(False))

        # ── Add all widgets
        self.layout.add_widget(self.title_label)
        self.layout.add_widget(self.last_night_label)
        self.layout.add_widget(self.risk_score_label)
        self.layout.add_widget(self.risk_sub_label)
        self.layout.add_widget(self.divider)
        self.layout.add_widget(self.stat1_label)
        self.layout.add_widget(self.stat2_label)
        self.layout.add_widget(self.stat3_label)
        self.layout.add_widget(self.insight_bg)
        self.layout.add_widget(self.insight_label)
        self.layout.add_widget(self.pattern_label)
        self.layout.add_widget(self.feedback_label)
        self.layout.add_widget(self.yes_btn)
        self.layout.add_widget(self.no_btn)

        self.add_widget(self.layout)

    # ─── CANVAS UPDATER ──────────────────────────────────────

    def _update_insight_bg(self, instance, *args):
        self.insight_rect.size = instance.size
        self.insight_rect.pos  = instance.pos

    # ─── SCREEN LIFECYCLE ────────────────────────────────────

    def on_enter(self):
        """Load data every time screen is opened"""
        self._load_session_data()

    # ─── LOAD SESSION DATA ───────────────────────────────────

    def _load_session_data(self):
        """
        Fetch last night's data from Firebase.
        Falls back to local cache if offline.
        Shows loading state while fetching.
        """
        self.risk_score_label.text = '...'
        self.insight_label.text    = 'Loading your insight...'

        import threading
        from core.queue_manager import QueueManager

        def _fetch():
            queue = QueueManager()
            prefs = queue.get_prefs()
            user_id = prefs.get('user_id')

            if user_id:
                from firebase.firestore import FirestoreManager
                fs = FirestoreManager(user_id, queue)
                fs.get_last_session(
                    lambda data: Clock.schedule_once(
                        lambda dt: self._update_ui(data), 0
                    )
                )
            else:
                # Not logged in — use cache
                cache = queue.get_cache()
                Clock.schedule_once(
                    lambda dt: self._update_ui(cache), 0
                )

        threading.Thread(target=_fetch, daemon=True).start()

    # ─── UPDATE UI WITH DATA ─────────────────────────────────

    def _update_ui(self, data: dict):
        """
        Fill all UI elements with session data.
        Called on main thread via Clock.schedule_once
        """
        if not data:
            self._show_no_data()
            return

        self.session_data = data

        # ── Risk score with color coding
        risk = data.get('riskScore', '--')
        self.risk_score_label.text = risk

        risk_colors = {
            'Low':    (0.6, 0.88, 0.7, 1),    # soft green
            'Medium': (0.95, 0.85, 0.5, 1),   # soft yellow
            'High':   (0.88, 0.55, 0.55, 1),  # soft red
        }
        self.risk_score_label.color = risk_colors.get(
            risk, (0.85, 0.88, 0.95, 0.9)
        )

        # ── Stats
        screen_time = data.get('totalScreenTime', 0)
        unlocks     = data.get('unlockCount', 0)
        longest     = data.get('longestSession', 0)

        self.stat1_label.text = f'Screen time\n{screen_time} mins'
        self.stat2_label.text = f'Unlocks\n{unlocks}'
        self.stat3_label.text = f'Longest session\n{longest} mins'

        # ── Pattern
        pattern = data.get('pattern', '')
        if pattern:
            self.pattern_label.text = f'Pattern: {pattern}'

        # ── Generate insight based on data
        self.insight_label.text = self._generate_insight(
            risk, screen_time, unlocks, longest
        )

        # ── Hide feedback if already given
        if data.get('feedbackGiven'):
            self._hide_feedback()

    def _show_no_data(self):
        """Show when no session data available"""
        self.risk_score_label.text  = '--'
        self.insight_label.text     = (
            'No data from last night yet.\n'
            'Check back after your first tracked night.'
        )
        self.stat1_label.text = 'Screen time\n--'
        self.stat2_label.text = 'Unlocks\n--'
        self.stat3_label.text = 'Longest session\n--'

    # ─── INSIGHT GENERATOR ───────────────────────────────────

    def _generate_insight(self, risk: str,
                           screen_time: int,
                           unlocks: int,
                           longest: int) -> str:
        """
        Generate one personalized insight based on last night.
        Simple rule-based for now — can be replaced with NLP later.
        """
        if risk == 'High':
            if screen_time > 40:
                return (
                    'You spent a lot of time on your phone last night. '
                    'Try putting it face-down 30 mins before sleep.'
                )
            elif unlocks > 10:
                return (
                    'Frequent phone checks can signal restlessness. '
                    'A short breathing exercise before bed may help.'
                )
            else:
                return (
                    'Last night showed high sleep disruption. '
                    'Consider a wind-down routine tonight.'
                )
        elif risk == 'Medium':
            if longest > 15:
                return (
                    'One long session late at night was detected. '
                    'Try setting a soft limit after 11 PM.'
                )
            else:
                return (
                    'Moderate activity last night. '
                    'You are on the right track — small adjustments help.'
                )
        elif risk == 'Low':
            return (
                'Great night. Low phone activity detected. '
                'Keep this rhythm going.'
            )
        else:
            return (
                'Your sleep data will appear here '
                'after your first tracked night.'
            )

    # ─── FEEDBACK ────────────────────────────────────────────

    def _save_feedback(self, helped: bool):
        """Save feedback and hide feedback section"""
        import threading
        from core.queue_manager import QueueManager

        def _save():
            queue   = QueueManager()
            prefs   = queue.get_prefs()
            user_id = prefs.get('user_id')
            risk    = self.session_data.get('riskScore', '--')

            if user_id:
                from firebase.firestore import FirestoreManager
                fs = FirestoreManager(user_id, queue)
                fs.save_feedback(helped=helped, risk_score=risk)

        threading.Thread(target=_save, daemon=True).start()

        # Update UI immediately
        Clock.schedule_once(
            lambda dt: self._show_feedback_thanks(helped), 0
        )

    def _show_feedback_thanks(self, helped: bool):
        """Replace feedback buttons with thank you message"""
        if helped:
            self.feedback_label.text  = 'Great. Keep it up tonight.'
            self.feedback_label.color = (0.6, 0.88, 0.7, 0.8)
        else:
            self.feedback_label.text  = 'Noted. We will adjust for tonight.'
            self.feedback_label.color = (0.7, 0.78, 0.95, 0.8)

        self._hide_feedback()

    def _hide_feedback(self):
        """Hide feedback buttons after response"""
        self.yes_btn.opacity  = 0
        self.yes_btn.disabled = True
        self.no_btn.opacity   = 0
        self.no_btn.disabled  = True