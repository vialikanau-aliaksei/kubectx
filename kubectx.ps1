Param(
    [Parameter(Mandatory=$false)]
    [string]$action,
    [Parameter(Mandatory=$false)]
    [string]$name,
    [Parameter(Mandatory=$false)]
    [string]$newname
    )

function usage() {
  Write-Output "
      Usage 
        kubectx                        : select context
        kubectx ls                     : list the contexts
        kubectx set <name>             : switch to context <name>
        kubectx rn <oldname> <newname> : rename context <oldname> <newname>
        kubectx rm <name>              : delete context <name>
        kubectx help                   : display usage"
}

function current_context() {
    kubectl config view -o=jsonpath='{.current-context}'
}

function delete_context() {
    kubectl config delete-context $name
}

function rename_context() {
    kubectl config rename-context $name $newname
}

function get_contexts() {
    kubectl config get-contexts -o=name | Sort-Object
  }
  
function select_context() {
    $gctx = (get_contexts)
    $cur = (current_context)

    $choice = fShowMenu "Choose context" $gctx $cur
    kubectl config use-context $choice
}

function list_contexts() {
    $gctx = (get_contexts)
    $cur = (current_context)
    ForEach ($i in $gctx) {
        if ($i -eq $cur) {
            Write-Host "*" $i -ForegroundColor Red
        } else {
            Write-Host $i
        }
    }
}

function switch_context($context) {
    kubectl config use-context $context
}

function main() {
    switch ($action) {
        set { switch_context $name }
        Default { select_context }
        ls { list_contexts }
        rn { rename_context }
        rm { delete_context }
        help { usage }
    }
}

function fShowMenu($sMenuTitle,[array]$hMenuEntries, $default)
{
    $iSavedBackgroundColor=[System.Console]::BackgroundColor
    $iSavedForegroundColor=[System.Console]::ForegroundColor
    # Menu Colors
    # inverse fore- and backgroundcolor 
    $iMenuForeGroundColor=$iSavedForegroundColor
    $iMenuBackGroundColor=$iSavedBackgroundColor
    $iMenuBackGroundColorSelectedLine=$iMenuForeGroundColor
    $iMenuForeGroundColorSelectedLine=$iMenuBackGroundColor
    # Init
    $iMenuStartLineAbsolute=0
    $iMenuLoopCount=0
    $iMenuSelectLine=1
    $iMenuEntries=$hMenuEntries.Count
    $hMenu=@{};
    $hMenuHotKeyList=@{};
    $hMenuHotKeyListReverse=@{};
    $iMenuHotKeyChar=0
    $sValidChars=""
    [System.Console]::WriteLine(" "+$sMenuTitle)
    $iMenuLoopCount=1
    # Start Hotkeys from "1"!
    $iMenuHotKeyChar=49
    for($i = 0; $i -le $hMenuEntries.Count; $i++){
        $sKey = $hMenuEntries[$i]
        if ($sKey -eq $default) {
            $iMenuSelectLine = ($i + 1)
        }
        $hMenu.Add($iMenuLoopCount,$sKey)
        # Hotkey assignment to the menu item
        $hMenuHotKeyList.Add($iMenuLoopCount,[System.Convert]::ToChar($iMenuHotKeyChar))
        $hMenuHotKeyListReverse.Add([System.Convert]::ToChar($iMenuHotKeyChar),$iMenuLoopCount)
        $sValidChars+=[System.Convert]::ToChar($iMenuHotKeyChar)
        $iMenuLoopCount++
        $iMenuHotKeyChar++
        
        if ($iMenuHotKeyChar -eq 58) {
            $iMenuHotKeyChar=97
        } elseif ($iMenuHotKeyChar -eq 123) {
            $iMenuHotKeyChar=65
        } elseif ($iMenuHotKeyChar -eq 91) {
            Write-Error " Menu too big!"
            exit(99)
        }
    }
    # Remember Menu start
    $iBufferFullOffset=0
    $iMenuStartLineAbsolute=[System.Console]::CursorTop
    do{
        ####### Draw Menu  #######
        [System.Console]::CursorTop=($iMenuStartLineAbsolute-$iBufferFullOffset)
        for ($iMenuLoopCount=1;$iMenuLoopCount -le $iMenuEntries;$iMenuLoopCount++){
            [System.Console]::Write("`r")
            $sPreMenuline=""
            $sPreMenuline="  "+$hMenuHotKeyList[$iMenuLoopCount]
            $sPreMenuline+=": "
            if ($iMenuLoopCount -eq $iMenuSelectLine){
                [System.Console]::BackgroundColor=$iMenuBackGroundColorSelectedLine
                [System.Console]::ForegroundColor=$iMenuForeGroundColorSelectedLine
            }
            if ($hMenuEntries[$iMenuLoopCount - 1].Length -gt 0){
                [System.Console]::Write($sPreMenuline+$hMenuEntries[$iMenuLoopCount - 1])
            }
            else{
                [System.Console]::Write($sPreMenuline+$hMenu.Item($iMenuLoopCount))
            }
            [System.Console]::BackgroundColor=$iMenuBackGroundColor
            [System.Console]::ForegroundColor=$iMenuForeGroundColor
            [System.Console]::WriteLine("")
        }
        [System.Console]::BackgroundColor=$iMenuBackGroundColor
        [System.Console]::ForegroundColor=$iMenuForeGroundColor
        if (($iMenuStartLineAbsolute+$iMenuLoopCount) -gt [System.Console]::BufferHeight){
            $iBufferFullOffset=($iMenuStartLineAbsolute+$iMenuLoopCount)-[System.Console]::BufferHeight
        }
        ####### End Menu #######
        ####### Read Key from Console 
        $oInputChar=[System.Console]::ReadKey($true)
        # Down Arrow?
        if ($oInputChar.Key -eq [System.ConsoleKey]::DownArrow){
            if ($iMenuSelectLine -lt $iMenuEntries){
                $iMenuSelectLine++
            }
        }
        # Up Arrow
        elseif($oInputChar.Key -eq [System.ConsoleKey]::UpArrow){
            if ($iMenuSelectLine -gt 1){
                $iMenuSelectLine--
            }
        }
        [System.Console]::BackgroundColor=$iMenuBackGroundColor
        [System.Console]::ForegroundColor=$iMenuForeGroundColor
    } while(($oInputChar.Key -ne [System.ConsoleKey]::Enter) -and ($sValidChars.IndexOf($oInputChar.KeyChar) -eq -1))
    
    # reset colors
    [System.Console]::ForegroundColor=$iSavedForegroundColor
    [System.Console]::BackgroundColor=$iSavedBackgroundColor
    if($oInputChar.Key -eq [System.ConsoleKey]::Enter){
        return($hMenu.Item($iMenuSelectLine))
    }
    else{
        return($hMenu[$hMenuHotKeyListReverse[$oInputChar.KeyChar]])
    }
}

main