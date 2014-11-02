# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

module WinAPI
  begin
    require "fiddle/import"
    extend Fiddle::Importer
  rescue LoadError
    # Fiddle がない環境用(http://www.artonx.org/data/asr/ の1.9.3とか)
    require "dl/import"
    extend DL::Importer
  end

  begin
    dlload "msvcrt", "kernel32"
  rescue DL::DLError
    dlload "crtdll", "kernel32"
  end
  extern "long GetLogicalDrives()"
  extern "unsigned long SetConsoleTextAttribute(unsigned long, unsigned long)"
  extern "unsigned long GetConsoleScreenBufferInfo(unsigned long, void*)"
  extern "unsigned long GetStdHandle(unsigned long)"
  extern "long GetLastError()"
  extern "unsigned long _getch()"
end
