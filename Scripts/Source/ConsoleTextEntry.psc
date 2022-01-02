scriptName ConsoleTextEntry extends Quest

float property Lock auto
string property LastResult auto
GlobalVariable Property ConsoleTextEntry_InProgress auto

event OnInit()
    RegisterForMenu("Console")
endEvent

event OnMenuOpen(string menuName)
    if menuName == "Console"
        if ConsoleTextEntry_InProgress.Value
            ; Um, what? How could we open it _while_ it's already open?
            ; Cancel!
            LastResult = ""
            ConsoleTextEntry_InProgress.Value = 0 ; <--- unblock things so the last GetText() can complete
        endIf
    endIf
endEvent

event OnMenuClose(string menuName)
    if menuName == "Console"
        ; Cancel the search if still marked as InProgress when the ~ console menu was closed
        if ConsoleTextEntry_InProgress.Value
            LastResult = ""
            ConsoleTextEntry_InProgress.Value = 0 ; <--- unblock things so the last GetText() can complete
        endIf
    endIf
endEvent

string function GetText(string prompt = "Enter text:", bool openConsole = true, bool closeConsole = true, float _lock = 0.0, float _waitInterval = 0.5) global
    if ! UI.GetBool("Console", "_global.Console.SupportsCustomCommands")
        Debug.Trace("[ADDSTUFF] [ConsoleTextEntry] Error: console.swf does not support custom commands. Make sure to put ConsoleTextEntry at the bottom of the load order. Note: currently incompatible with More Informative Console")
        Debug.Trace("[ADDSTUFF] [ConsoleTextEntry] Error: console.swf does not support custom commands. Make sure to put ConsoleTextEntry at the bottom of the load order. Note: currently incompatible with More Informative Console")
        ; return ""
    endIf

    _lock = Utility.RandomFloat(0, 1000000)

    ConsoleTextEntry textEntry = Game.GetFormFromFile(0x800, "ConsoleTextEntry.esp") as ConsoleTextEntry
    GlobalVariable inProgress = Game.GetFormFromFile(0x802, "ConsoleTextEntry.esp") as GlobalVariable

    while textEntry.Lock
        Utility.WaitMenuMode(_waitInterval)
    endWhile

    textEntry.Lock = _lock

    if textEntry.Lock == _lock
        if textEntry.Lock == _lock

            textEntry.RegisterForKey(28)  ; Enter
            textEntry.RegisterForKey(156) ; Return

            UI.SetBool("Console", "_global.Console.HandleEnterKey", false)

            string history = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text")
            string currentSelection = UI.GetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text")
            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", prompt)
            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", "")
            UI.SetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text", "")

            UI.SetBool("Console", "_global.Console.HandleEnterKey", false)

            if openConsole && ! UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                Debug.Trace("[ADDSTUFF] TAPPING KEY")
                Input.TapKey(41) ; ~
                Utility.WaitMenuMode(1)

                if ! UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                    ; TODO make this a help message!
                    Debug.Notification("AddStuffMenu: Please put your cursor into VR game")
                    Utility.WaitMenuMode(5)
                    if ! UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                        ; TODO make this a help message!
                        Debug.Notification("AddStuffMenu: Console not opened, canceling")
                        return ""
                    endIf
                endIf
                ; Debug.Trace
                ; Debug.Trace("[ADDSTUFF] Tapped key...")
                ; int attempts = 0
                ; while ! UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown") ; Wait for it to open
                ;     attempts += 1
                ;     if attempts > 10
                ;         Debug.Trace("[ADDSTUFF] Could not open ~ console")
                ;         textEntry.Lock = 0
                ;         return ""
                ;     endIf
                ;     Utility.WaitMenuMode(0.5)
                ; endWhile
            endIf
            
            UI.SetBool("Console", "_global.Console.HandleEnterKey", false)

            if ! history
                history = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text")
            endIf
            if ! currentSelection
                currentSelection = UI.GetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text")
            endIf
            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", prompt)
            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", "")
            UI.SetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text", "")

            Debug.Trace("[ADDSTUFF] Waiting for you to enter text")

            string result
            inProgress.Value = 1
            while inProgress.Value
                Utility.WaitMenuMode(_waitInterval)
            endWhile
            result = textEntry.LastResult

            Debug.Trace("[ADDSTUFF] GOT RESULT: " + result)

            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", "")
            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", history)
            UI.SetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text", currentSelection)
            UI.SetBool("Console", "_global.Console.HandleEnterKey", true)

            if closeConsole && UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                Input.TapKey(41) ; ~
                while UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown") ; Wait for it to close
                    Utility.WaitMenuMode(0.5)
                endWhile
            endIf

            textEntry.Lock = 0

            Debug.Trace("[ADDSTUFF] RETURNING")

            return result
        else
            return GetText(prompt, openConsole, closeConsole, _lock, _waitInterval)
        endIf
    else
        return GetText(prompt, openConsole, closeConsole, _lock, _waitInterval)
    endIf
endFunction

event OnKeyDown(int keyCode)
    if ConsoleTextEntry_InProgress.Value && (keyCode == 28 || keyCode == 156)
        UnregisterForKey(28)  ; Enter
        UnregisterForKey(156) ; Return
        LastResult = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text")
        if ! LastResult
            LastResult = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text")
        endIf
        ConsoleTextEntry_InProgress.Value = 0
    endIf
endEvent
