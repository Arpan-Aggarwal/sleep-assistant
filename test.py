import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager, FadeTransition
from kivy.uix.screenmanager import Screen
from screens.onboarding import OnboardingScreen
from screens.home_night import HomeNightScreen
from screens.home_day import HomeDayScreen


class SupportScreen(Screen):
    pass


class TestApp(App):
    def build(self):
        sm = ScreenManager(transition=FadeTransition(duration=0.5))
        sm.add_widget(OnboardingScreen(name='onboarding'))
        sm.add_widget(HomeNightScreen(name='home_night'))
        sm.add_widget(HomeDayScreen(name='home_day'))
        sm.add_widget(SupportScreen(name='support'))

        # Change to 'home_day' to test day screen directly
        sm.current = 'home_day'
        return sm


TestApp().run()