from urllib.request import urlopen
import xmltodict
import csv


networks = [
  "dlf"
]


def map_values(arr):
  resp = []
  resp.append(arr[0].keys())
  for a in arr:
    resp.append(a.values())
  return resp

def to_csv(arr):
  with open("python_export.csv", "w") as myfile:
    wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
    for a in arr:
      wr.writerow(a)

def get_property_keys(type):
  if type == "episode":
    return {
      "id": "video_id",
      "title": "title",
      "showId": "show_id",
      "seasonNumber": "season_num",
      "episodeNumber": "episode_num",
      "rating": "parental_rating",
      "subType": "video_type",
      "type": "type",
      "seasonId": "season_id", 
      "duration": "duration", 
      "publishDate": "publish_date", 
      "airDate": "air_date",
      "license": {
        "startDate": "start_date",
        "endDate": "end_date"
      },
      "networks": {
        "network": "network_code"
      }
    }
  elif (type == "event" or type == "limited"):
    return {
      "id": "video_id",
      "title": "title",
      "showId": "show_id",
      "seasonNumber": "season_num",
      "episodeNumber": "episode_num",
      "rating": "parental_rating",
      "subType": "video_type",
      "type": "type",
      "seasonId": "season_id", 
      "duration": "duration", 
      "publishDate": "publish_date", 
      "airDate": "air_date",
      "license": {
        "startDate": "start_date",
        "endDate": "end_date"
      },
      "networks": {
        "network": "network_code"
      }
    }
  else: 
    return {
      "id": "video_id",
      "title": "title",
      "showId": "show_id",
      "seasonNumber": "season_num",
      "episodeNumber": "episode_num",
      "rating": "parental_rating",
      "subType": "video_type",
      "type": "type",
      "seasonId": "season_id", 
      "duration": "duration", 
      "publishDate": "publish_date", 
      "airDate": "air_date",
      "license": {
        "startDate": "start_date",
        "endDate": "end_date"
      },
      "networks": {
        "network": "network_code"
      }
    }

def get_content():
  networks = [
    "dlf",
    "ahc"
  ]
  content = []
  for net in networks:
    url = "http://api.discovery.com/feeds/vidora/{0}/vidora-catalog".format(net)
    file = urlopen(url)
    data = file.read()
    file.close()
    data = xmltodict.parse(data)
    series = {}
    seasons = {}
    # for item in data["contentFeed"]["item"][:10]:
    for item in data["contentFeed"]["item"]:
      if item["contentType"] == "show":
        series[item["id"]] = item["title"]
      elif item["contentType"] == "season":
        seasons[item["id"]] = item["title"]
      else:
        video = {"network_code": net, "show_title": series[item["showId"]]}
        props = get_property_keys(item["subType"])
        for attrib in item.keys():
          if attrib in props:
            if type(props[attrib]) is str: 
              video[props[attrib]] = item[attrib]
            if type(props[attrib]) is dict:
              for k in props[attrib]:
                video[props[attrib][k]] = item[attrib][k]
        if (video["video_type"] == "event" or video["video_type"] == "limited"):
          video["season_id"] = None
        content.append(video)
  content = map_values(content)
  # to_csv(content)
  return content



