import api
import algorithm, random, math, sequtils
import strutils
import nimga

randomize()

var decorateRequest: DecorateRequest
var teamInfo: TeamInfo
teamInfo.teamName = "Gentastic"
teamInfo.teamMembers = "Dennis, Remco"

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

var
  pop, popNext: Population
  crossovered: CrossoveredChrom
  a, b: int


proc mapToEntry*(chrom: seq[int]): Entry =

    var line: string

    for i in 0..<chrom.len-2:
       line.add(allowedChars[chrom[i]])

    result.line = line
    result.number = chrom[chrom.len-1]

proc mutateMe*(pop: Population, mutationNum :int = 1): Population =
  ##
  ## Mutate chrome twice of pop
  ##
  deepCopy(result, pop)

  var targetChild, targetChrom: int

  for i in 0..mutationNum:
      targetChild = rand(pop.len - 1)
      targetChrom = rand(pop[targetChild].chrom.len - 1)

      var value: int
      if targetChrom == pop[targetChild].chrom.len - 1:
        value = rand(high(int32))
      else:
        value = rand(allowedChars.len-1)

      result[targetChild].chrom[targetChrom] = value

proc createPopulation*(popRange:int): Population =
  ##
  ## Create population
  ## Chrom is binary.
  ##
  ## Example: individual.chrom = @[1, 1, 0, 1, 0]
  ##
  result = @[]

  var newIndividual: Individual

  for i in 0..<popRange:
    newIndividual = Individual(chrom: @[], score: 0.0)
    for j in 0..<rand(keyStatus.currentKeyNumber):
      newIndividual.chrom.add(rand(allowedChars.len-1))

    newIndividual.chrom.add(rand(high(int32)))
    result.add(newIndividual)

proc runFloyd*(N, popLength, generateTime, saveElite: int): seq[int] =
  ###
  ### Floyd
  ###

  # Initial population
  pop = createPopulation(popLength)

  # Initial evaluation
  var entries: seq[Entry]
  # Map chrom to entry
  for j in 0..<popLength:
    entries.add(mapToEntry(pop[j].chrom))

  var evaluateRequest: EvaluateRequest
  evaluateRequest.playerId = playerJoinResponse.playerId
  evaluateRequest.entries = entries

  var response = httpPostEvaluate(evaluateRequest)

  # Evaluation
  for j in 0..<popLength:
    pop[j].score = response.entries[j].score

  # Sorting
  pop = sortIndividualsByScore(pop, order=Ascending)

  for i in 0..<generateTime:
    # Ready new generation
    popNext = selectElite(pop, saveElite)

    # Generation
    for j in countup(2, (popLength - saveElite) - 1, 2):
      # Selection
      a = rouletteSelection(map(pop, proc(p: Individual): float = p.score))
      b = rouletteSelection(map(pop, proc(p: Individual): float = p.score))

      # Crossover
      # crossovered = kPointCrossover(pop[a].chrom, pop[b].chrom, 1)

      # Add to new generation
      popNext.add(Individual(chrom: pop[a].chrom, score: 0.0))
      popNext.add(Individual(chrom: pop[b].chrom, score: 0.0))

    # Mutation
    if (willMutate(0.5)):
      popNext[saveElite..<popNext.len] = mutateMe(popNext[saveElite..<popNext.len], 1000)

    # Push new population when pops less than popLength
    if (popNext.len < popLength):
      popNext.add(createPopulation(popLength - popNext.len))

    var entries: seq[Entry]
    # Map chrom to entry
    for j in 0..<popLength:
        entries.add(mapToEntry(popNext[j].chrom))

    var evaluateRequest: EvaluateRequest
    evaluateRequest.playerId = playerJoinResponse.playerId
    evaluateRequest.entries = entries

    var response = httpPostEvaluate(evaluateRequest)

    # Evaluation
    for j in 0..<popLength:
      popNext[j].score = response.entries[j].score

    # Sorting
    popNext = sortIndividualsByScore(popNext, order=Ascending)

    # Copy `NextIndividualrationPopulation` to pop
    pop = popNext

    echo "Score at ", i + 1, "\t: ", pop[0].score

  # Set result
  result = pop[0].chrom

if isMainModule:
  echo runFloyd(50, 1000, 1000, 1)


#let num = rand(100)
#echo "A random number between 0 and 100: ", num

#var arrayExample = [1, 2, 3, 4, 5]
#var select = sample(arrayExample)
#echo "From an array I randomly picked: ", select

#var keyStatus = httpGetKeyStatus()
#echo "Current Key: ", keyStatus.currentKeyNumber
#echo "Expire on: ", keyStatus.expiresUtc

#var allowedChars = httpGetLegalCharacters();
#echo "legal chars: ", allowedChars
#echo "random one: ", sample(allowedChars)

#var chosenChar = 'F'
#var index = find(allowedChars, chosenChar);
#echo "I found char ", chosenChar, " at index ", index

