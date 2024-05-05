function Set-DSDiscordNickname {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter()]
        [string]
        $GuildID = '982809029355134997',

        [Parameter()]
        [string]
        $DSAuthToken = (Get-Content .\authtoken.txt -ErrorAction SilentlyContinue),

        [Parameter()]
        [string]
        $DiscordAuthToken = (Get-Content .\discord-authtoken.txt -ErrorAction SilentlyContinue)
    )
    
    $Headers = @{
        authorization = $DiscordAuthToken
    }

    $DiscordServerUrl = 'https://discord.com/api/v10/guilds/{0}' -f $GuildID
    try {
        $DiscordServer = Invoke-RestMethod -Uri $DiscordServerUrl -Headers $Headers
    }
    catch {
        "Failed to successfuly communicate with the Discord API. Error message is below:`n"
        $_
        return
    }

    $DiscordUserUrl = 'https://discord.com/api/v10/users/@me/guilds/{0}/member' -f $GuildID
    $DiscordUser = Invoke-RestMethod -Uri $DiscordUserUrl -Headers $Headers

    try {
        $DSUser = Get-DSUser -AuthToken $DSAuthToken
    }
    catch {
        "Failed to successfuly communicate with the Dreaming Spanish API. Error message is below:`n"
        $_
        return
    }

    $CurrentHours = [math]::Floor($DSUser.TotalTimeHours)
    $ReplaceString = '{0}$2' -f $CurrentHours

    $NewNickname = $DiscordUser.nick -replace '(\d+)(k?\s+(h|hours|hrs))', $ReplaceString
    if ($NewNickname -eq $DiscordUser.nick) {
        'Discord servername is already up to date: {0}' -f $DiscordUser.nick
        return
    }

    $Data = @{
        nick = $NewNickname
    }
    $DiscordServerName = $DiscordServer.name
    
    if ($PSCmdlet.ShouldProcess("Discord Server: $DiscordServerName", "Update Discord server nickname to: $NewNickname")) {
        try {
            $UpdateNickParams = @{
                Uri         = 'https://discord.com/api/v10/guilds/{0}/members/@me' -f $GuildID
                Headers     = $Headers
                Method      = 'PATCH'
                Body        = $Data | ConvertTo-Json -Compress
                ContentType = 'application/json'
            }
            $Response = Invoke-RestMethod @UpdateNickParams
            'Discord nickname has been updated from "{0}" to "{1}"' -f $DiscordUser.nick, $Response.nick
        }
        catch {
            "Failed to update nickname. Error is below:`n"
            $_
            return
        }
    }
}
