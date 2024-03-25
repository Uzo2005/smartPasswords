import sets, strutils, sequtils, random
import ./getInformation

type RuleConstraints* = enum
  IncludeConstraint
  ExcludeConstraint

type
  Rule* = object
    constraintType: RuleConstraints
    description: string

  RuleSet* = openArray[Rule]

proc includeRule*(description: string): Rule =
  Rule(constraintType: IncludeConstraint, description: description)

proc excludeRule*(description: string): Rule =
  Rule(constraintType: ExcludeConstraint, description: description)

proc validResults*(rule: Rule, exclude: string = ""): seq[string] =
  var query: string
  if exclude.len > 0:
    query = rule.description & ". This should not contain " & exclude
  else:
    query = rule.description

  result = query.getInformationFromGemini
    .strip(chars = {'"', ' '})
    .split(",")
    .mapit(it.strip)

proc generatePassword*(length: Slice | Natural, rules: RuleSet): string =
  #order of rule matters
  var
    includeSet, validSet: HashSet[seq[string]]
    excludeSet: HashSet[string]
    largeLength = rand(bool)
  
  let excludeStr = rules.filterit(it.constraintType == ExcludeConstraint).mapit(it.description).join(" and ")

  for rule in rules:
    case rule.constraintType
    of IncludeConstraint:
      includeSet.incl(rule.validResults(excludeStr))
    of ExcludeConstraint:
      for invalid in rule.validResults:
        excludeSet.incl(invalid)

  # echo "Initial Valid Set: ", includeSet
  # echo "Invalid Set: ", excludeSet

  for potentiallyValid in includeSet.items:
    validSet.incl(potentiallyValid.filterIt(it notin excludeSet))

  var itemsToExcl: HashSet[seq[string]]
  for potentiallyValid in validSet.items:
    for invalid in excludeSet.items:
      if potentiallyValid.contains(invalid):
        itemsToExcl.incl(potentiallyValid)

      for value in potentiallyValid:
        if value.contains(invalid):
          itemsToExcl.incl(potentiallyValid)

  validSet = validSet - itemsToExcl

  # echo "Final Valid set: ", validSet

  when length is Slice:
    let
      smallestLength = length.a
      biggestLength = length.b
  else:
    let
      smallestLength = length
      biggestLength = length

  if validSet.card > smallestLength:
    return "ERROR: the length provided is too small for all rules we want to satisfy"
    # return ""

  var minimumLengthFromSet: int
  for group in validSet.items:
    minimumLengthFromSet.inc(group.mapit(it.len).min)

  if minimumLengthFromSet > smallestLength:
    return "ERROR: the length provided is too small to satisfy the rules"
    # return ""

  var buildPassword = true
  var initialValidSet = validSet
  var tempResult: seq[string]

  while buildPassword:
    if validSet.card == 0:
      if initialValidSet.card == 0:
        return "ERROR: Seems like no combination of characters can satisy your rules"
        # return ""

      validSet = initialValidSet

    var mutValidSet = validSet

    for group in validSet.items:
      let currentSampleFromGroup = group.sample
      tempResult.add(currentSampleFromGroup)
      let adjustedGroup = group.filterIt(it != currentSampleFromGroup)
      mutValidSet.excl(group)
      if adjustedGroup.len > 0:
        mutValidSet.incl(adjustedGroup)

    # echo mutValidSet, " ++++ "
    # echo tempResult, " ---- -- "
    validSet = mutValidSet

    if tempResult.join.len > smallestLength and length is Slice:
      if largeLength:
        continue
      else:
        buildPassword = false

    if tempResult.join.len >= biggestLength:
      tempResult = tempResult.deduplicate()
      while true:
        if tempResult.join.len <= biggestLength:
          buildPassword = false
          break

        var smallestLengthIndex: int
        for index, str in tempResult:
          let
            currentStrLen = str.len
            prevStrLen = tempResult[smallestLengthIndex].len

          var smallerLen = min(currentStrLen, prevStrLen)

          if smallerLen == currentStrLen:
            smallestLengthIndex = index

        tempResult.delete(smallestLengthIndex)

  result = tempResult.join

  if result.len < biggestLength:
    if length is Slice:
      if largeLength:
        let charsNeeded = biggestLength - result.len
        let availableChars = (
          (Letters + Digits + PunctuationChars).toseq.mapIt($it).toHashSet - excludeSet
        ).toseq

        for i in 0 ..< charsNeeded:
          result.add(availableChars.sample)
    else:
      let charsNeeded = biggestLength - result.len
      let availableChars = (
        (Letters + Digits + PunctuationChars).toseq.mapIt($it).toHashSet - excludeSet
      ).toseq

      for i in 0 ..< charsNeeded:
        result.add(availableChars.sample)


when isMainModule:
  let
    exclude1 = excludeRule("the letter o")
    include1 = includeRule("popular board game")
    include2 = includeRule("one vowel")
    password = generatePassword(20, [exclude1, include1, include2])

  echo "Generated Password: ", password, " with length of ", password.len
