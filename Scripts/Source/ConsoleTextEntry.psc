scriptName ConsoleTextEntry extends Quest

float property Lock auto
string property LastResult auto
GlobalVariable Property ConsoleTextEntry_InProgress auto

event OnInit()
    RegisterForMenu("Console")
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

string function GetText(string prompt = "Enter text:", bool openConsole = true, bool closeConsole = true, float _lock = 0.0, float _waitInterval = 0.1) global
    if ! UI.GetBool("Console", "_global.Console.SupportsCustomCommands")
        Debug.Trace("[ConsoleTextEntry] Error: console.swf does not support custom commands. Make sure to put ConsoleTextEntry at the bottom of the load order. Note: currently incompatible with More Informative Console")
        return ""
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

            bool consolePreviouslyLoaded = UI.GetString("Console", "_global.Console.InstanceLoaded")
            string history
            string currentSelection
            if consolePreviouslyLoaded
                history = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text")
                currentSelection = UI.GetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text")
                UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", prompt)
                UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", "")
                UI.SetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text", "")
            endIf

            if openConsole && ! UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                Input.TapKey(41) ; ~
            endIf

            if ! consolePreviouslyLoaded ; None of the commands above would've worked without a ConsoleInstance - this is for first time ~ open
                history = UI.GetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text")
                currentSelection = UI.GetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text")
                UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", prompt)
                UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", "")
                UI.SetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text", "")
            endIf

            string result
            inProgress.Value = 1
            while inProgress.Value
                Utility.WaitMenuMode(_waitInterval)
            endWhile
            result = textEntry.LastResult

            if closeConsole && UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                Input.TapKey(41) ; ~
            endIf

            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.text", "")
            UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", history)
            UI.SetString("Console", "_global.Console.ConsoleInstance.CurrentSelection.text", currentSelection)
            UI.SetBool("Console", "_global.Console.HandleEnterKey", true)

            textEntry.Lock = 0

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
        ConsoleTextEntry_InProgress.Value = 0
    endIf
endEvent
