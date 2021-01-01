
(require 'iflipb)
(setq iflipb-wrap-around t)

(use-package pulseaudio-control)
(use-package backlight)

;; (use-package desktop-environment
;;   :after exwm
;;   :config (desktop-environment-mode)
;;   :custom
;;   (desktop-environment-brightness-small-increment "2%+")
;;   (desktop-environment-brightness-small-decrement "2%-")
;;   (desktop-environment-brightness-normal-increment "5%+")
;;   (desktop-environment-brightness-normal-decrement "5%-"))

(defun efs/run-in-background (command)
  (let ((command-parts (split-string command "[ ]+")))
    (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

(defun efs/set-wallpaper ()
  (interactive)
  ;; NOTE: You will need to update this to a valid background path!
  (start-process-shell-command
      "feh" nil  "feh --bg-scale /home/stavros/Downloads/42337.jpg"))
;; /usr/share/backgrounds/Raindrops_On_The_Table_by_Alex_Fazit.jpg"))

(defun efs/exwm-init-hook ()
  (exwm-workspace-switch-create 0)
  (find-file-other-window "~/.emacs.d/desktop.el")
  
  ;; Make workspace 1 be the one where we land at startup
  (exwm-workspace-switch-create 1)
  
  ;; Open eshell by default
  ;;(eshell)

  ;; Show battery status in the mode line
  (display-battery-mode 1)
  
  ;; Show the time and date in modeline
  (setq display-time-day-and-date t)
  (setq display-time-format "%H:%M %a %d/%m/%y")
  (display-time-mode 1)
  ;; Also take a look at display-time-format and format-time-string

  ;; Launch apps that will run in the background
  (efs/run-in-background "nm-applet")
  (efs/run-in-background "pasystray")
  (efs/run-in-background "blueman-applet")
  (efs/run-in-background "flameshot"))

(defun efs/exwm-update-class ()
  (exwm-workspace-rename-buffer exwm-class-name))

(use-package exwm
  :config
  ;; Set the default number of workspaces
  (setq exwm-workspace-number 5)
  
  ;; Load the system tray before exwm-init
  (require 'exwm-systemtray)
  (setq exwm-systemtray-height 24)
  (exwm-systemtray-enable)
  
  ;; When EXWM starts up, do some extra confifuration
  (add-hook 'exwm-init-hook #'efs/exwm-init-hook)
  ;; When window "class" updates, use it to set the buffer name
  (add-hook 'exwm-update-class-hook #'efs/exwm-update-class)
  ;; Language
  (set-input-method "greek")
  (toggle-input-method)

  ;; When EXWM finishes initialization, do some extra setup
  ;; (add-hook 'exwm-init-hook #'efs/after-exwm-init)

  ;; For me, xmodmap to disable key 94 (sc 86, char "<")
  (start-process-shell-command "xmodmap" nil "xmodmap ~/.emacs.d/exwm/Xmodmap")
  ;; For me, touchpad id is 16 (or 15) ('xinput list') and Tapping Enabled 320 ('xinput list-props <id>')
  (start-process-shell-command "xinput" nil "xinput set-prop 16 320 1") ;; Touchpad click on tap
  (start-process-shell-command "xinput" nil "xinput set-prop 16 302 1") ;; Touchpad natural scrolling
  
  ;; Set the screen resolution
  (require 'exwm-randr)
  (exwm-randr-enable)
  (start-process-shell-command "xrandr" nil "xrandr --output Virtual-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal")

  ;; Set the wallpaper after changing the resolution
  (efs/set-wallpaper)

  ;; These keys should always pass through to Emacs
  (setq exwm-input-prefix-keys
    '(?\C-x
      ?\C-u
      ?\C-h
      ?\M-x
      ?\M-`
      ?\M-&
      ?\M-:
      ?\C-\M-j  ;; Buffer list
      ?\C-\ ))  ;; Ctrl+Space

  ;; Ctrl+Q will enable the next key to be sent directly
  (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

  ;; Set up global key bindings.  These always work, no matter the input state!
  ;; Keep in mind that changing this list after EXWM initializes has no effect.
  (setq exwm-input-global-keys
        `(
          ;; Reset to line-mode (C-c C-k switches to char-mode via exwm-input-release-keyboard)
          ([?\s-r] . exwm-reset)

          ;; Move between windows
          ([s-left] . windmove-left)
          ([s-right] . windmove-right)
          ([s-up] . windmove-up)
          ([s-down] . windmove-down)
	  ([XF86AudioRaiseVolume] . pulseaudio-control-increase-volume)
	  ([XF86AudioLowerVolume] . pulseaudio-control-decrease-volume)
	  ([XF86AudioMute] . pulseaudio-control-toggle-current-sink-mute)
	  ([XF86MonBrightnessUp] . backlight-inc)
	  ([XF86MonBrightnessDown] . backlight-dec)
	  ([?\M-A] . toggle-input-method)
	  ([M-tab] . iflipb-next-buffer)
	  ([M-iso-lefttab] . iflipb-previous-buffer)
	  ([?\s-l] . desktop-environment-lock-screen)
	  ([print] . (lambda ()
		       (interactive)
		       (let ((path (concat "~/Documents/Screenshot-" (format-time-string "%Y-%m-%d,%H:%M:%S") ".png")))
			 (start-process-shell-command
			  "import" nil (concat "import -window root " path))
			 (message (concat "Screenshot saved to " path)))
		       ))
	  
          ;; Launch applications via shell command
          ([?\s-&] . (lambda (command)
                       (interactive (list (read-shell-command "$ ")))
                       (start-process-shell-command command nil command)))

          ;; Switch workspace
          ([?\s-w] . exwm-workspace-switch)

          ;; 's-N': Switch to certain workspace with Super (Win) plus a number key (0 - 9)
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))

  (exwm-input-set-key (kbd "s-SPC") 'counsel-linux-app)
  ;; (exwm-input-set-key (kbd "s-f") 'exwm-layout-toggle-fullscreen)
  
  (exwm-enable))

;; Set frame transparency
(set-frame-parameter (selected-frame) 'alpha '(87 . 87))
(add-to-list 'default-frame-alist '(alpha . (87 . 87)))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(use-package counsel
  :custom
  (counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only))
