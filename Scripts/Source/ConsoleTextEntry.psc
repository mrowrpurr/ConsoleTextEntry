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

; TODO - EXTRACT THINGS INTO FUNCTIONS! TO DO THINGS LIKE LOCK/UNLOCK THE CONSOLE and OPEN/CLOSE and shit like that :) and to STYLE IT!!!

string function GetText(string prompt = "Enter text:", bool openConsole = true, bool closeConsole = true, float _lock = 0.0, float _waitInterval = 0.5) global


    StyleConsole()


    _lock = Utility.RandomFloat(0, 1000000) ; Only one mod can use the console at a time!

    ConsoleTextEntry textEntry = Game.GetFormFromFile(0x800, "ConsoleTextEntry.esp") as ConsoleTextEntry ; Gets the instance of the ConsoleTextEntry script (which can listen for Key events, e.g. the <Enter> key)
    GlobalVariable inProgress = Game.GetFormFromFile(0x802, "ConsoleTextEntry.esp") as GlobalVariable ; Global for checking whether the ConsoleTextEntry is currently open/busy

    while textEntry.Lock
        Utility.WaitMenuMode(_waitInterval) ; Defaults to checking that the console is ready twice a second
    endWhile

    textEntry.Lock = _lock

    if textEntry.Lock == _lock
        if textEntry.Lock == _lock

            textEntry.RegisterForKey(28)  ; Enter
            textEntry.RegisterForKey(156) ; Return

            UI.SetBool("Console", "_global.Console.HandleEnterKey", false) ; Tell the custom console.swf (if it's in use) to handle enter keys!
            UI.SetBool("Console", "_global.Console.HandleEnterKey", false) ; Do it again because weird Flash things

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
            
            UI.SetBool("Console", "_global.Console.HandleEnterKey", false) ; 
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

            ; TODO ! CHECK IF 'COMMAND NOT FOUND' ! AND CLEAR THAT TEXT. To support vanilla console and More Informative too :) Test using More Informative :)

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

            UI.SetBool("Console", "_global.Console.HandleEnterKey", true) ; Let the console handle commands as usual again (if using custom console.swf)
            UI.SetBool("Console", "_global.Console.HandleEnterKey", true)

            if closeConsole && UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown")
                Input.TapKey(41) ; ~
                ; while UI.GetBool("Console", "_global.Console.ConsoleInstance.Shown") ; Wait for it to close
                ;     Utility.WaitMenuMode(0.5)
                ; endWhile
                Utility.WaitMenuMode(0.5)
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


int function GetScreenHeight() global
    return Utility.GetINIINt("iSize H:Display")
endFunction

; Helper function to provide full screen width
int function GetScreenWidth() global
    return Utility.GetINIInt("iSize W:Display")
endFunction

function StyleConsole() global
    ; float width = GetScreenWidth() / 2

    ; Debug.MessageBox("Console Y: " + UI.GetFloat("Console", "_global.Console.ConsoleInstance._y")) ; 340
    UI.SetFloat("Console", "_global.Console.ConsoleInstance._y", ((GetScreenHeight() / 3) * -1))
    ; Debug.MessageBox("Console X: " + UI.GetFloat("Console", "_global.Console.ConsoleInstance._x")) ; 0 ?
    UI.SetFloat("Console", "_global.Console.ConsoleInstance._x", (GetScreenWidth() / 5))

    UI.SetBool("Console", "_global.Console.ConsoleInstance.Background._visible", false)

    UI.SetBool("Console", "_global.Console.ConsoleInstance.CurrentSelection._visible", false)

    ; Debug.MessageBox("History x " + UI.GetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._x")) ; 70
    ; Debug.MessageBox("History y " + UI.GetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._y")) ; -381
    ; UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._y", ((GetScreenHeight() / 2) * -1))
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._y", 69)
    UI.SetBool("Console", "_global.Console.ConsoleInstance.CommandHistory.background", true)
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.backgroundColor", "0x000000")
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.text", "Please enter something:")
    UI.SetBool("Console", "_global.Console.ConsoleInstance.CommandHistory.border", true)
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandHistory.borderColor", "0xffffff")
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandHistory._width", GetScreenWidth() / 2)

    ; Debug.MessageBox("Entry x " + UI.GetFloat("Console", "_global.Console.ConsoleInstance.CommandEntry._x")) ; 70
    ; Debug.MessageBox("Entry y " + UI.GetFloat("Console", "_global.Console.ConsoleInstance.CommandEntry._y")) ; -85
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandEntry._y", -335) ; <--- YAY
    UI.SetBool("Console", "_global.Console.ConsoleInstance.CommandEntry.background", true)
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.backgroundColor", "0x000000")
    UI.SetBool("Console", "_global.Console.ConsoleInstance.CommandEntry.border", true)
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.borderColor", "0xffffff")
    UI.SetString("Console", "_global.Console.ConsoleInstance.CommandEntry.textColor", "0xffffff")
    UI.SetFloat("Console", "_global.Console.ConsoleInstance.CommandEntry._width", GetScreenWidth() / 2)
endFunction
