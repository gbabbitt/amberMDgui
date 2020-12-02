#!/usr/bin/env python
import os
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import ObjectProperty

print("Welcome to AMBER MD GUI- a simple graphical user interface for GPU accelerated AMBER molecular dynamic simulations")
cmd = 'gedit READMEambermd.md'
os.system(cmd)
print("finding paths for paths.ctl") 
cmd = 'perl PATHSamber.pl'
os.system(cmd)


class AMBERMDApp(App):
#    kv_directory = 'kivy_templates'
    def build(self):
        return MyLayout()
   
class MyLayout(Widget):
    
      
    # define buttons and actions
    def btn1(self):
        print("running AMBER MD - protein force field only") 
        cmd = 'perl GUI_START_AMBERss1.pl'
        os.system(cmd)
    def btn2(self):
        print("running AMBER MD - protein and DNA force field") 
        cmd = 'perl GUI_START_AMBERdp1.pl'
        os.system(cmd)
    def btn3(self):
        print("running AMBER MD - protein and ligand modified GAFF force field") 
        cmd = 'perl GUI_START_AMBERlp1.pl'
        os.system(cmd)
       


if __name__ == '__main__':
    AMBERMDApp().run()
