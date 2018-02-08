# from urllib.request import urlopen
import requests
from xml.etree import ElementTree
import csv
import datetime
import os



def filename(base=False):
  base = base if base != False else "csv_export"
  today = datetime.datetime.now()
  today_string = today.strftime('%m%d%y')
  filename = base + "_" + today_string
  return filename


def map_values(arr):
  resp = []
  resp.append(arr[0].keys())
  for a in arr:
    resp.append(a.values())
  return resp

def to_csv(arr, file_name=False, file_path=""):
  file_path = file_path if (len(file_path) == 0 or file_path[len(file_path) - 1] == "/") else file_path + "/"
  if ((len(file_path) > 0) and (not os.path.exists(file_path))):
    os.makedirs(file_path)
  with open(file_path + filename(file_name) + ".csv", "w") as myfile:
    wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
    for a in arr:
      wr.writerow(a)

def video_props():
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


def parse_xml(export_csv=False):
  net = "dlf"
  content = []
  url = "http://api.discovery.com/feeds/vidora/{0}/vidora-catalog".format(net)
  response = requests.get(url)
  tree = ElementTree.fromstring(response.content)
  series = {}
  seasons = {}
  for item in tree.findall("item"):
    if item.find("contentType").text == "show":
      series[item.find("id").text] = item.find("title").text
    elif item.find("contentType").text == "season":
      seasons[item.find("id").text] = item.find("title").text
    else:
      video = {"network_code": net, "show_title": series[item.find("showId").text]}
      props = video_props()
      for child in item.getchildren():
        if child.tag in props:
          if type(props[child.tag]) is str:
            video[props[child.tag]] = child.text
          if type(props[child.tag]) is dict:
            for k in props[child.tag]:
              video[props[child.tag][k]] = child.find(k).text
      if (video["video_type"] == "event" or video["video_type"] == "limited"):
          video["season_id"] = None
      content.append(video)
  content = map_values(content)
  if export_csv == True:
    to_csv(content)
  return content
