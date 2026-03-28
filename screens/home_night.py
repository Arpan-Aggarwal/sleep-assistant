# screens/home_night.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from kivy.uix.screenmanager import Screen
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.graphics import Color, Rectangle, Ellipse
from kivy.animation import Animation
from kivy.clock import Clock


class HomeNightScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.pulse_anim = None
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

        # ── App title
        self.title_label = Label(
    text='Sleep Assistant',
    font_size='13sp',
    color=(0.48, 0.56, 0.75, 0.5),
    halign='center',
    pos_hint={'center_x': 0.5, 'center_y': 0.95}  # changed
)

        # ── Risk indicator
        self.risk_label = Label(
            text='',
            font_size='11sp',
            color=(0.48, 0.56, 0.75, 0.4),
            halign='center',
            pos_hint={'center_x': 0.5, 'top': 0.91}
        )

        # ── Glow ring (drawn with Ellipse = perfect circle)
        self.glow_widget = Widget(
            size_hint=(None, None),
            size=(240, 240),
            pos_hint={'center_x': 0.5, 'center_y': 0.58}
        )
        with self.glow_widget.canvas:
            Color(0.1, 0.13, 0.22, 0.5)
            self.glow_ellipse = Ellipse(
                size=self.glow_widget.size,
                pos=self.glow_widget.pos
            )
        self.glow_widget.bind(
            size=self._update_glow,
            pos=self._update_glow
        )

        # ── Breathing circle (drawn with Ellipse = perfect circle)
        self.circle_widget = Widget(
            size_hint=(None, None),
            size=(185, 185),
            pos_hint={'center_x': 0.5, 'center_y': 0.58}
        )
        with self.circle_widget.canvas:
            Color(0.11, 0.14, 0.24, 1)
            self.circle_ellipse = Ellipse(
                size=self.circle_widget.size,
                pos=self.circle_widget.pos
            )
        self.circle_widget.bind(
            size=self._update_circle,
            pos=self._update_circle
        )

        # ── Text inside circle
        self.circle_text = Label(
            text='breathe',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.5),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.58}
        )

        # ── Main calm text
        self.calm_label = Label(
            text='Everything is quiet.',
            font_size='17sp',
            color=(0.85, 0.88, 0.95, 0.9),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.35}
        )

        # ── Subtitle
        self.sub_label = Label(
            text='Rest easy.',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.6),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.30}
        )

        # ── Helper text
        self.helper_label = Label(
            text='tap below if your mind is restless',
            font_size='11sp',
            color=(0.48, 0.56, 0.75, 0.4),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.21}
        )

        # ── Support button (added last so it receives taps)
        self.support_btn = Button(
            text='I need support',
            font_size='15sp',
            size_hint=(0.65, None),
            height=50,
            pos_hint={'center_x': 0.5, 'center_y': 0.13},
            background_color=(0.15, 0.19, 0.32, 1),
            background_normal='',
            color=(0.7, 0.78, 0.95, 1)
        )
        self.support_btn.bind(on_press=self._open_support)

        # ── Add in order (interactive widgets last)
        self.layout.add_widget(self.title_label)
        self.layout.add_widget(self.risk_label)
        self.layout.add_widget(self.glow_widget)
        self.layout.add_widget(self.circle_widget)
        self.layout.add_widget(self.circle_text)
        self.layout.add_widget(self.calm_label)
        self.layout.add_widget(self.sub_label)
        self.layout.add_widget(self.helper_label)
        self.layout.add_widget(self.support_btn)

        self.add_widget(self.layout)

    # ─── ELLIPSE UPDATERS ────────────────────────────────────

    def _update_glow(self, instance, *args):
        self.glow_ellipse.size = instance.size
        self.glow_ellipse.pos  = instance.pos

    def _update_circle(self, instance, *args):
        self.circle_ellipse.size = instance.size
        self.circle_ellipse.pos  = instance.pos

    # ─── SCREEN LIFECYCLE ────────────────────────────────────

    def on_enter(self):
        self._start_breathing()
        self._load_risk_status()

    def on_leave(self):
        if self.pulse_anim:
            self.pulse_anim.cancel(self.circle_widget)

    # ─── BREATHING ANIMATION ─────────────────────────────────

    def _start_breathing(self):
        """
        Animates the Widget size — Ellipse follows via bind
        4 seconds grow, 4 seconds shrink — infinite loop
        """
        grow = Animation(
            size=(205, 205),
            duration=4,
            t='in_out_sine'
        )
        shrink = Animation(
            size=(175, 175),
            duration=4,
            t='in_out_sine'
        )
        glow_grow = Animation(
            size=(260, 260),
            duration=4,
            t='in_out_sine'
        )
        glow_shrink = Animation(
            size=(225, 225),
            duration=4,
            t='in_out_sine'
        )

        # Text fades in and out with breathing
        text_fade_out = Animation(
            color=(0.48, 0.56, 0.75, 0.1),
            duration=4,
            t='in_out_sine'
        )
        text_fade_in = Animation(
            color=(0.48, 0.56, 0.75, 0.5),
            duration=4,
            t='in_out_sine'
        )

        self.pulse_anim        = grow + shrink
        self.pulse_anim.repeat = True
        self.pulse_anim.start(self.circle_widget)

        glow_loop        = glow_grow + glow_shrink
        glow_loop.repeat = True
        glow_loop.start(self.glow_widget)

        text_loop        = text_fade_out + text_fade_in
        text_loop.repeat = True
        text_loop.start(self.circle_text)

    # ─── LOAD RISK STATUS ────────────────────────────────────

    def _load_risk_status(self):
        import threading
        from core.queue_manager import QueueManager

        def _check():
            queue = QueueManager()
            cache = queue.get_cache()
            risk  = cache.get('riskScore', '')
            Clock.schedule_once(
                lambda dt: self._update_risk_display(risk), 0
            )

        threading.Thread(target=_check, daemon=True).start()

    def _update_risk_display(self, risk: str):
        indicators = {
            'Low':    'calm night',
            'Medium': 'light activity detected',
            'High':   'active night detected',
        }
        self.risk_label.text = indicators.get(risk, '')

    # ─── OPEN SUPPORT ────────────────────────────────────────

    def _open_support(self, instance):
        if 'support' in self.manager.screen_names:
            self.manager.current = 'support'
        else:
            self.calm_label.text = 'Support coming soon...'
            Clock.schedule_once(
                lambda dt: setattr(
                    self.calm_label, 'text', 'Everything is quiet.'
                ), 2
            )
