#! /usr/bin/env python
import sys, csv, bz2

def main(argv=None):
  if argv is None:
    argv = sys.argv
    argv.pop(0)
  f = bz2.BZ2File(argv.pop(0), 'r')
#  f = open(argv.pop(0), 'r')
  indb = csv.DictReader(f, dialect='excel-tab')
  ns = indb.fieldnames[-14:]
  idref = {}
  for x in indb:
    idref[x['NiteID']] = dict(zip(ns, [x[k] for k in ns]))
  f.close()
  f = open(argv.pop(0), 'rb')
  indb = csv.DictReader(f, dialect='excel-tab')
  col = argv.pop(0)
  ncols = [col + '_' + k for k in ns]
  fn = indb.fieldnames + ncols
  try:
    out = argv.pop(0)
  except IndexError:
    out = sys.stdout
  outdb = csv.DictWriter(out, fieldnames=fn, dialect='excel-tab')
  outdb.writeheader()
  for x in indb:
    cdata = idref.get(x[col], {})
    x.update(zip(ncols, [cdata.get(k, '') for k in ns]))
    outdb.writerow(x)
  f.close()

if __name__ == '__main__':
  main()
