# screens/support.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from kivy.uix.screenmanager import Screen
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.widget import Widget
from kivy.graphics import Color, Rectangle, Ellipse, RoundedRectangle
from kivy.animation import Animation
from kivy.clock import Clock


class SupportScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_view  = 'menu'   # menu / breathe / journal
        self.breathe_anim  = None
        self.breathe_phase = 'inhale'
        self._build_ui()

    # ─── BACKGROUND ──────────────────────────────────────────

    def _set_background(self):
        with self.canvas.before:
            Color(0.03, 0.04, 0.08, 1)   # slightly darker than night screen
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

        # ── Back button (top left)
        self.back_btn = Button(
            text='< back',
            font_size='13sp',
            size_hint=(None, None),
            size=(80, 36),
            pos_hint={'x': 0.04, 'top': 0.97},
            background_color=(0, 0, 0, 0),
            background_normal='',
            color=(0.48, 0.56, 0.75, 0.6)
        )
        self.back_btn.bind(on_press=self._go_back)

        # ── Title
        self.title_label = Label(
            text='I am here.',
            font_size='20sp',
            color=(0.85, 0.88, 0.95, 0.9),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.88}
        )

        # ── Subtitle
        self.sub_label = Label(
            text='What would help right now?',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.6),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.82}
        )

        # ── 4 support cards
        self.breathe_btn = self._make_card(
            title='Breathe',
            subtitle='4-7-8 breathing exercise',
            pos_y=0.68,
            on_press=self._show_breathe
        )

        self.journal_btn = self._make_card(
            title='Write it out',
            subtitle='One quiet prompt, no pressure',
            pos_y=0.53,
            on_press=self._show_journal
        )

        self.sounds_btn = self._make_card(
            title='Calm sounds',
            subtitle='Rain, white noise, silence',
            pos_y=0.38,
            on_press=self._show_sounds
        )

        self.talk_btn = self._make_card(
            title='Talk',
            subtitle='Type what is on your mind',
            pos_y=0.23,
            on_press=self._show_talk
        )

        # ── Add menu widgets
        self.layout.add_widget(self.back_btn)
        self.layout.add_widget(self.title_label)
        self.layout.add_widget(self.sub_label)
        self.layout.add_widget(self.breathe_btn)
        self.layout.add_widget(self.journal_btn)
        self.layout.add_widget(self.sounds_btn)
        self.layout.add_widget(self.talk_btn)

        self.add_widget(self.layout)

    def _make_card(self, title, subtitle, pos_y, on_press):
        """Create a soft card button"""
        btn = Button(
            text=f'{title}\n{subtitle}',
            font_size='14sp',
            halign='center',
            size_hint=(0.85, None),
            height=65,
            pos_hint={'center_x': 0.5, 'center_y': pos_y},
            background_color=(0.11, 0.14, 0.24, 1),
            background_normal='',
            color=(0.85, 0.88, 0.95, 0.9)
        )
        btn.bind(on_press=on_press)
        return btn

    # ─── SCREEN LIFECYCLE ────────────────────────────────────

    def on_enter(self):
        self._show_menu()

    def on_leave(self):
        self._stop_breathe_anim()

    # ─── NAVIGATION ──────────────────────────────────────────

    def _go_back(self, instance):
        self._stop_breathe_anim()
        if self.current_view != 'menu':
            self._show_menu()
        else:
            self.manager.current = 'home_night'

    def _show_menu(self):
        """Show the main 4 option menu"""
        self.current_view = 'menu'
        self._clear_dynamic_widgets()

        self.title_label.text = 'I am here.'
        self.sub_label.text   = 'What would help right now?'

        for w in [self.breathe_btn, self.journal_btn,
                  self.sounds_btn, self.talk_btn,
                  self.sub_label]:
            w.opacity  = 1
            w.disabled = False

    def _clear_dynamic_widgets(self):
        """Remove any dynamically added widgets"""
        to_remove = [w for w in self.layout.children
                     if getattr(w, '_dynamic', False)]
        for w in to_remove:
            self.layout.remove_widget(w)
        self._stop_breathe_anim()

    def _hide_menu_cards(self):
        """Hide the 4 cards when showing a sub-view"""
        for w in [self.breathe_btn, self.journal_btn,
                  self.sounds_btn, self.talk_btn,
                  self.sub_label]:
            w.opacity  = 0
            w.disabled = True

    # ─── BREATHE VIEW ────────────────────────────────────────

    def _show_breathe(self, instance=None):
        """Show 4-7-8 breathing animation"""
        self.current_view = 'breathe'
        self._clear_dynamic_widgets()
        self._hide_menu_cards()

        self.title_label.text = 'Breathe with this'
        self._stop_breathe_anim()

        # ── Outer ring
        self.breathe_glow = Widget(
            size_hint=(None, None),
            size=(230, 230),
            pos_hint={'center_x': 0.5, 'center_y': 0.55}
        )
        self.breathe_glow._dynamic = True
        with self.breathe_glow.canvas:
            Color(0.1, 0.13, 0.22, 0.4)
            self.breathe_glow_ellipse = Ellipse(
                size=self.breathe_glow.size,
                pos=self.breathe_glow.pos
            )
        self.breathe_glow.bind(
            size=lambda i, v: setattr(
                self.breathe_glow_ellipse, 'size', v),
            pos=lambda i, v: setattr(
                self.breathe_glow_ellipse, 'pos', v)
        )

        # ── Main breathing circle
        self.breathe_circle = Widget(
            size_hint=(None, None),
            size=(160, 160),
            pos_hint={'center_x': 0.5, 'center_y': 0.55}
        )
        self.breathe_circle._dynamic = True
        with self.breathe_circle.canvas:
            Color(0.15, 0.19, 0.35, 1)
            self.breathe_ellipse = Ellipse(
                size=self.breathe_circle.size,
                pos=self.breathe_circle.pos
            )
        self.breathe_circle.bind(
            size=lambda i, v: setattr(
                self.breathe_ellipse, 'size', v),
            pos=lambda i, v: setattr(
                self.breathe_ellipse, 'pos', v)
        )

        # ── Instruction text
        self.breathe_instruction = Label(
            text='Inhale',
            font_size='18sp',
            color=(0.85, 0.88, 0.95, 0.9),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.55}
        )
        self.breathe_instruction._dynamic = True

        # ── Count label
        self.breathe_count = Label(
            text='4',
            font_size='32sp',
            bold=True,
            color=(0.48, 0.56, 0.75, 0.7),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.47}
        )
        self.breathe_count._dynamic = True

        # ── Pattern label
        self.breathe_pattern = Label(
            text='4 - 7 - 8  breathing',
            font_size='11sp',
            color=(0.48, 0.56, 0.75, 0.4),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.29}
        )
        self.breathe_pattern._dynamic = True

        # ── Stop button
        self.breathe_stop = Button(
            text='stop',
            font_size='13sp',
            size_hint=(0.4, None),
            height=40,
            pos_hint={'center_x': 0.5, 'center_y': 0.20},
            background_color=(0.11, 0.14, 0.24, 1),
            background_normal='',
            color=(0.48, 0.56, 0.75, 0.6)
        )
        self.breathe_stop._dynamic = True
        self.breathe_stop.bind(on_press=lambda x: self._show_menu())

        self.layout.add_widget(self.breathe_glow)
        self.layout.add_widget(self.breathe_circle)
        self.layout.add_widget(self.breathe_instruction)
        self.layout.add_widget(self.breathe_count)
        self.layout.add_widget(self.breathe_pattern)
        self.layout.add_widget(self.breathe_stop)

        # Start the 4-7-8 cycle
        self._run_breathe_cycle()

    def _run_breathe_cycle(self):
        """
        4-7-8 breathing:
          Inhale for 4 seconds
          Hold for 7 seconds
          Exhale for 8 seconds
        """
        self._breathe_inhale()

    def _breathe_inhale(self):
        self.breathe_instruction.text = 'Inhale'
        self._countdown(4, self._breathe_hold)
        grow = Animation(size=(200, 200), duration=4, t='in_out_sine')
        grow.start(self.breathe_circle)
        glow = Animation(size=(270, 270), duration=4, t='in_out_sine')
        glow.start(self.breathe_glow)

    def _breathe_hold(self):
        self.breathe_instruction.text = 'Hold'
        self._countdown(7, self._breathe_exhale)

    def _breathe_exhale(self):
        self.breathe_instruction.text = 'Exhale'
        self._countdown(8, self._breathe_inhale)
        shrink = Animation(size=(140, 140), duration=8, t='in_out_sine')
        shrink.start(self.breathe_circle)
        glow = Animation(size=(210, 210), duration=8, t='in_out_sine')
        glow.start(self.breathe_glow)

    def _countdown(self, seconds: int, on_done):
        """Count down seconds updating the count label"""
        self._remaining    = seconds
        self._breathe_done = on_done
        self._tick(0)

    def _tick(self, dt):
        if self.current_view != 'breathe':
            return
        if self._remaining > 0:
            self.breathe_count.text = str(self._remaining)
            self._remaining -= 1
            Clock.schedule_once(self._tick, 1)
        else:
            self.breathe_count.text = ''
            self._breathe_done()

    def _stop_breathe_anim(self):
        if hasattr(self, 'breathe_circle'):
            Animation.cancel_all(self.breathe_circle)
        if hasattr(self, 'breathe_glow'):
            Animation.cancel_all(self.breathe_glow)

    # ─── JOURNAL VIEW ────────────────────────────────────────

    def _show_journal(self, instance=None):
        self.current_view = 'journal'
        self._clear_dynamic_widgets()
        self._hide_menu_cards()

        self.title_label.text = 'Write it out'

        prompts = [
            'What is making it hard to sleep?',
            'What is on your mind right now?',
            'What would make tomorrow feel easier?',
            'What do you need to let go of tonight?'
        ]
        import random
        prompt = random.choice(prompts)

        # ── Prompt label
        self.journal_prompt = Label(
            text=prompt,
            font_size='14sp',
            color=(0.7, 0.78, 0.95, 0.8),
            halign='center',
            text_size=(320, None),
            pos_hint={'center_x': 0.5, 'center_y': 0.72}
        )
        self.journal_prompt._dynamic = True

        # ── Text input
        self.journal_input = TextInput(
            hint_text='Just write... no one will judge this.',
            multiline=True,
            size_hint=(0.85, None),
            height=200,
            pos_hint={'center_x': 0.5, 'center_y': 0.50},
            background_color=(0.08, 0.10, 0.18, 1),
            foreground_color=(0.85, 0.88, 0.95, 0.9),
            hint_text_color=(0.48, 0.56, 0.75, 0.3),
            cursor_color=(0.48, 0.56, 0.75, 1),
            padding=[14, 14]
        )
        self.journal_input._dynamic = True

        # ── Save note button
        self.journal_save = Button(
            text='done',
            font_size='13sp',
            size_hint=(0.4, None),
            height=42,
            pos_hint={'center_x': 0.5, 'center_y': 0.22},
            background_color=(0.15, 0.19, 0.32, 1),
            background_normal='',
            color=(0.7, 0.78, 0.95, 1)
        )
        self.journal_save._dynamic = True
        self.journal_save.bind(on_press=self._save_journal)

        self.layout.add_widget(self.journal_prompt)
        self.layout.add_widget(self.journal_input)
        self.layout.add_widget(self.journal_save)

    def _save_journal(self, instance):
        """Save journal entry locally"""
        text = self.journal_input.text.strip()
        if text:
            from core.queue_manager import QueueManager
            from datetime import datetime
            queue = QueueManager()
            entries = queue._read_file(
                'data/journal.json', default=[]
            )
            entries.append({
                'text':      text,
                'timestamp': datetime.now().isoformat()
            })
            queue._write_file('data/journal.json', entries)

        # Show thank you then go back to menu
        self.title_label.text = 'Saved. Rest now.'
        Clock.schedule_once(lambda dt: self._show_menu(), 2)

    # ─── SOUNDS VIEW ─────────────────────────────────────────

    def _show_sounds(self, instance=None):
        self.current_view = 'sounds'
        self._clear_dynamic_widgets()
        self._hide_menu_cards()

        self.title_label.text = 'Calm sounds'

        sounds = [
            ('Rain',        'rain.mp3'),
            ('White noise', 'white_noise.mp3'),
            ('Deep silence', None)
        ]

        for i, (name, file) in enumerate(sounds):
            btn = Button(
                text=name,
                font_size='15sp',
                size_hint=(0.7, None),
                height=52,
                pos_hint={
                    'center_x': 0.5,
                    'center_y': 0.65 - (i * 0.15)
                },
                background_color=(0.11, 0.14, 0.24, 1),
                background_normal='',
                color=(0.85, 0.88, 0.95, 0.8)
            )
            btn._dynamic = True
            btn.bind(on_press=lambda x, f=file, n=name:
                    self._play_sound(f, n))
            self.layout.add_widget(btn)

        note = Label(
            text='Audio coming in next update',
            font_size='11sp',
            color=(0.48, 0.56, 0.75, 0.3),
            halign='center',
            pos_hint={'center_x': 0.5, 'center_y': 0.22}
        )
        note._dynamic = True
        self.layout.add_widget(note)

        # ── Back to menu button
        back = Button(
            text='back to menu',
            font_size='13sp',
            size_hint=(0.5, None),
            height=42,
            pos_hint={'center_x': 0.5, 'center_y': 0.10},
            background_color=(0.11, 0.14, 0.24, 1),
            background_normal='',
            color=(0.48, 0.56, 0.75, 0.6)
        )
        back._dynamic = True
        back.bind(on_press=lambda x: self._show_menu())
        self.layout.add_widget(back)

    def _play_sound(self, filename, name):
        self.title_label.text = f'Playing: {name}'

    # ─── TALK VIEW ───────────────────────────────────────────

    def _show_talk(self, instance=None):
        self.current_view = 'talk'
        self._clear_dynamic_widgets()
        self._hide_menu_cards()

        self.title_label.text = 'I am listening.'

        # ── Chat display area
        self.chat_display = Label(
            text='Type what is on your mind.\nNo judgment here.',
            font_size='13sp',
            color=(0.48, 0.56, 0.75, 0.6),
            halign='center',
            text_size=(320, None),
            pos_hint={'center_x': 0.5, 'center_y': 0.68}
        )
        self.chat_display._dynamic = True

        # ── Text input
        self.chat_input = TextInput(
            hint_text='What is on your mind...',
            multiline=False,
            size_hint=(0.75, None),
            height=46,
            pos_hint={'center_x': 0.42, 'center_y': 0.38},
            background_color=(0.08, 0.10, 0.18, 1),
            foreground_color=(0.85, 0.88, 0.95, 0.9),
            hint_text_color=(0.48, 0.56, 0.75, 0.3),
            cursor_color=(0.48, 0.56, 0.75, 1),
            padding=[12, 12]
        )
        self.chat_input._dynamic = True

        # ── Send button
        self.chat_send = Button(
            text='send',
            font_size='13sp',
            size_hint=(0.18, None),
            height=46,
            pos_hint={'center_x': 0.88, 'center_y': 0.38},
            background_color=(0.15, 0.19, 0.32, 1),
            background_normal='',
            color=(0.7, 0.78, 0.95, 1)
        )
        self.chat_send._dynamic = True
        self.chat_send.bind(on_press=self._send_message)

        # ── Back to menu button
        back = Button(
            text='back to menu',
            font_size='13sp',
            size_hint=(0.5, None),
            height=42,
            pos_hint={'center_x': 0.5, 'center_y': 0.22},
            background_color=(0.11, 0.14, 0.24, 1),
            background_normal='',
            color=(0.48, 0.56, 0.75, 0.6)
        )
        back._dynamic = True
        back.bind(on_press=lambda x: self._show_menu())
        self.layout.add_widget(back)

        self.layout.add_widget(self.chat_display)
        self.layout.add_widget(self.chat_input)
        self.layout.add_widget(self.chat_send)


## Why The Back Button Wasn't Working



    def _send_message(self, instance):
        """Simple calm response — no AI yet"""
        text = self.chat_input.text.strip()
        if not text:
            return

        responses = [
            'That makes sense. You are not alone in feeling this.',
            'Thank you for sharing that. Rest when you can.',
            'It is okay to feel this way. Tomorrow is a new start.',
            'I hear you. Try to breathe slowly for a moment.',
        ]
        import random
        response = random.choice(responses)

        self.chat_display.text = (
            f'You: {text}\n\n{response}'
        )
        self.chat_display.color = (0.85, 0.88, 0.95, 0.8)
        self.chat_input.text    = ''