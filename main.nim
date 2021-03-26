import api
import algorithm, random, math, sequtils
import strutils

randomize()

var decorateRequest: DecorateRequest
var teamInfo: TeamInfo
teamInfo.teamName = "Gentastic"
teamInfo.teamMembers = "Dennis, Remco, Lili"

decorateRequest.clientId = "SuperMegaSecretToTheMax"
decorateRequest.teamInfo = teamInfo
httpPostDecorate(decorateRequest)

var playerJoinRequest: PlayerJoinRequest
playerJoinRequest.clientId = "SuperMegaSecretToTheMax"
playerJoinRequest.playerName = "ChromosomeXY"

var playerJoinResponse = httpPostPlayerJoin(playerJoinRequest)

var allowedChars = httpGetLegalCharacters();
echo "legal chars: ", allowedChars
echo "legal chars: ", allowedChars.len

var keyStatus = httpGetKeyStatus()
echo "Current Key: ", keyStatus.currentKeyNumber
echo "Expire on: ", keyStatus.expiresUtc


proc createEntry(number: int): Entry = 
 result.line = "a"
 result.number = number


proc fillEntries(first:int, last:int): seq[Entry] =
    var lFirst, lLast, lTemp: int
    lLast = last
    lFirst = first
    if(lFirst > lLast):
        lTemp = lLast
        lLast = lFirst
        lFirst = lTemp

    result.add(createEntry(lFirst))
    result.add(createEntry((lLast - lFirst) div 2 + lFirst))
    result.add(createEntry((lLast - lFirst) div 4 + lFirst))
    result.add(createEntry(((lLast - lFirst) div 4 * 3).int + lFirst))
    result.add(createEntry(lLast))

    sort(
        result,
        proc (x, y: Entry): int = cmp(x.number, y.number),
        Ascending
    )

proc calculateNumbers(first:int, last:int):int =
    var evaluateRequest: EvaluateRequest
    evaluateRequest.playerId = playerJoinResponse.playerId
    evaluateRequest.entries = fillEntries(first, last)
    var response = httpPostEvaluate(evaluateRequest)

    sort(
            response.entries,
            proc (x, y: Entry): int = cmp(x.score, y.score),
            Descending
        )

    echo "-"
    for i in 0..<response.entries.len:
        echo response.entries[i]

    echo abs(response.entries[0].number - response.entries[1].number)
    if (abs(response.entries[0].number - response.entries[1].number) < 3):
        return response.entries[0].number
    else:
        calculateNumbers(response.entries[0].number, response.entries[1].number)


echo calculateNumbers(0, high(int32))