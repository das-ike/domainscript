if [ ! -n "$1" ]; then 
 echo "No Domain given, exiting..."
 exit 1
fi

CONFDIR=configs
TEMPLATE=template
HOST=dax
DUPLICATES=$CONFDIR/duplicate-domains.txt
DOMAINFILE=$CONFDIR/existing-domains.txt
DOMAIN=$1


BASEDIR=$(pwd)
if [ ! -d "$CONFDIR" ]; then
 echo "confdir not found, creating..."
 mkdir $CONFDIR
fi

cd $BASEDIR && rsync -e ssh -r $HOST:/etc/nginx/sites/synced/  $CONFDIR/  --exclude=off

if [ ! -n "$2" ]; then
OLDORIGIN=$(cat $DOMAINFILE | grep $DOMAIN | cut -d : -f2)
 if [ -n "$OLDORIGIN" ];then
  ORIGIN="$OLDORIGIN"
  echo "Domain existing in old config, using original Origin $ORIGIN"
  echo $DOMAIN >> $DUPLICATES
  else
 ORIGIN=$(dig +short $DOMAIN)
 echo "Origin-IP not set, will be using IP from DNS: $ORIGIN"
 fi

 
 if [ -z "$ORIGIN" ]; then
  echo "DNS failure or no IP specified, please enter IP manually"
  exit 1
fi
 
 else
  ORIGIN=$2
fi

IDENTIFIER=$(head /dev/urandom | tr -dc a-z0-9 | head -c 10 ; echo '')

if [ ! -d "$TEMPLATE" ]; then
 echo "Error: template dir not found!"
 exit 1
fi
cd $BASEDIR && rsync -e ssh -r $HOST:/etc/nginx/sites/synced/  $CONFDIR/  --exclude=off
DOMAINDIR=$(find $CONFDIR -maxdepth 1 -type d -name "$DOMAIN*"  -print -quit)

if [ -z "$DOMAINDIR" ]; then
 echo "Domain not set, setting to"
 cp -r $TEMPLATE/* $CONFDIR/ && cd $CONFDIR && mv conf.conf $DOMAIN-$IDENTIFIER.conf && mv confdir $DOMAIN-$IDENTIFIER && sed -i -- "s/IDENTIFIER/$IDENTIFIER/g" $DOMAIN-$IDENTIFIER.conf &&  sed -i -- "s/DOMAIN/$DOMAIN/g" $DOMAIN-$IDENTIFIER.conf
 DOMAINDIR=$CONFDIR/$DOMAIN-$IDENTIFIER
 cd $DOMAIN-$IDENTIFIER && sed -i -- "s/IDENTIFIER/$IDENTIFIER/g" * && sed -i -- "s/DOMAIN/$DOMAIN/g" * && sed -i -- "s/IPADDR/$ORIGIN/g" site.inc
 echo $DOMAINDIR
 
else
 LENGTH=$(expr length $CONFDIR)
 CLENGTH=$((LENGTH+1))
 IDENTIFIER=$(echo $DOMAINDIR |sed 's/.*\(..........\)/\1/' )
 DOMAIN=$(echo $DOMAINDIR | sed "s/...........$//g"| sed -r 's/^.{'$CLENGTH'}//' ) 
 echo "Domain" $DOMAIN "already set, changing Origin-IP to" $ORIGIN
 
 cp $TEMPLATE/confdir/site.inc $DOMAINDIR
 cd $DOMAINDIR && sed -i -- "s/IDENTIFIER/$IDENTIFIER/g" site.inc && sed -i -- "s/DOMAIN/$DOMAIN/g" site.inc && sed -i -- "s/IPADDR/$ORIGIN/g" site.inc
fi

cd $BASEDIR && rsync -e ssh -r $CONFDIR/* $HOST:/etc/nginx/sites/synced && echo "----sync for "$DOMAIN" complete"
