import httpclient, uri, parsecfg, json

template getValue(env: Config, key: string): string =
  env.getSectionValue("", key)

template getWolframApiUrl(query: string, appID: string): string =
  $(parseUri(Wolfram_BASEURL) ? {"appid": appID, "i": query})

template getGeminiApiUrl(apiKey: string): string =
  $(parseUri(Gemini_BASEURL) ? {"key": apiKey})

const
  Wolfram_BASEURL = "http://api.wolframalpha.com/v1/result"
  Gemini_BASEURL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent"

# let
#   query1 = "best artist of the renassaince"
#   query2 = "letter w"

proc getInformationFromWolfram*(query: string): string =
  let
    env = loadConfig(".env")
    wolframAppId = env.getValue("WOLFRAM_APP_ID")

  let
    client = newHttpClient()
    requestUrl = getWolframApiUrl(query, wolframAppId)

  try:
    result = client.getContent(requestUrl)
  except HttpRequestError as e:
    if e.msg == "501 Not Implemented":
      result = ""

      if not defined(release):
        echo "This query does not have a short answer"
  finally:
    client.close()

proc getInformationFromGemini*(query: string): string {.gcsafe.} =
  let
    env = loadConfig(".env")
    geminiApiKey = env.getValue("GEMINI_API_KEY")
  let
    client = newHttpClient()
    requestUrl = getGeminiApiUrl(geminiApiKey)
    postBody =
      %*{
        "contents": [
          {
            "parts": [
              {"text": "input: 3 names of dogs"},
              {"text": "output: coco, bingo, bobby"},
              {"text": "input: 5 states in Nigeria"},
              {"text": "output: anambra, ebonyi, imo"},
              {"text": "input: recent epidemic virus"},
              {"text": "output: corona"},
              {"text": "input: name of cat"},
              {"text": "output: kitty"},
              {"text": "input: letters a to z"},
              {
                "text":
                  "output: a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z"
              },
              {"text": "input: letters A to Z"},
              {
                "text":
                  "output: A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z"
              },
              {"text": "input: latest marvel movie"},
              {"text": "output: endgame"},
              {"text": "input: cool board games"},
              {"text": "output: monopoly, checkers"},
              {"text": "input: 5 cool board games"},
              {"text": "output: monopoly, checkers, chess, ludo, scrabble"},
              {"text": "input: city in nigeria whose spelling is only 2 letters"},
              {"text": "output: nil"},
              {"text": "input: female president of USA"},
              {"text": "output: nil"},
              {"text": "input: jonathan coulton'\''s popular song"},
              {"text": "output: still alive"},
              {"text": "input: jonathan coulton'\''s popular songs"},
              {"text": "output: still alive, shopvac"},
              {"text": "input: name of marvel character"},
              {"text": "output: spiderman"},
              {"text": "input: name of marvel character. length=6"},
              {"text": "output: vision"},
              {"text": "input: name of marvel character.length>10"},
              {"text": "output: captain america"},
              {"text": "input: name of marvel character.length<10"},
              {"text": "output: storm"},
              {"text": "input: cities in Africa. length<10"},
              {"text": "output: abuja, accra"},
              {"text": "input: letter w"},
              {"text": "output: w"},
              {"text": "input: all letters and digits"},
              {
                "text":
                  "output: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z"
              },
              {"text": "input: " & query},
              {"text": "output: "},
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.9,
          "topK": 1,
          "topP": 1,
          "maxOutputTokens": 2048,
          "stopSequences": [],
        },
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_ONLY_HIGH",
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_ONLY_HIGH",
          },
        ],
      }
    # contentType = "application/json"
  var it: string
  try:
    let geminiResponse = parseJson client.postContent(requestUrl, $postBody)
    it = $geminiResponse
    result = $geminiResponse["candidates"][0]["content"]["parts"][0]["text"]
  except Exception as e:
    result = ""

    if not defined(release):
      echo "An error occured when asking gemini for information on: ", query
      echo it
  finally:
    client.close()

# echo query1.getInformationFromWolfram
# echo query1.getInformationFromGemini
