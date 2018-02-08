import go_api
import civis
import os
import datetime


def to_csv(arr, file_name=False, file_path=""):
  file_path = file_path if (len(file_path) == 0 or file_path[len(file_path) - 1] == "/") else file_path + "/"
  if ((len(file_path) > 0) and (not os.path.exists(file_path))):
    os.makedirs(file_path)
  with open(file_path + filename(file_name) + ".csv", "w") as myfile:
    wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
    for a in arr:
      wr.writerow(a)

go_api.get_content()

# def go():
#   return go_api.get_content()

# go()