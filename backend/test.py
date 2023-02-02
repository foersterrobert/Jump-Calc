import requests

# create game using POST
response = requests.post("http://localhost:5000/game/0/Player1")
responseJson = response.json()
print(responseJson)

# start game using PATCH
response = requests.patch(f"http://localhost:5000/game/{responseJson['game_id']}/start")

