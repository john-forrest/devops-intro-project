#!/bin/bash -eux
# nginx web server plugins
apt-get -y install uwsgi-plugin-python uwsgi

# reqs for Graphite
apt-get install -y python-pip
apt-get install -y python-dev libcairo2-dev libffi-dev build-essential
export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
pip install https://github.com/graphite-project/ceres/tarball/master
pip install --no-binary=:all: https://github.com/graphite-project/whisper/tarball/master
pip install --no-binary=:all: https://github.com/graphite-project/carbon/tarball/master
pip install --no-binary=:all: https://github.com/graphite-project/graphite-web/tarball/master

# make config files from examples
cd /opt/graphite/conf/
mkdir examples; mv *.example examples
cp examples/storage-schemas.conf.example storage-schemas.conf
cp examples/storage-aggregation.conf.example storage-aggregation.conf
cp examples/carbon.conf.example carbon.conf
cp examples/graphite.wsgi.example wsgi.py
cp /opt/graphite/webapp/graphite/{local_settings.py.example,local_settings.py}

cat <<EOF > /etc/uwsgi/apps-available/graphite.ini
[uwsgi] 
	processes = 2 
	socket = 127.0.0.1:3031 
	gid = www-data
	uid = www-data
	chdir = /opt/graphite/conf 
	module = wsgi:application
	manage-script-name = true
EOF

ln -s /etc/uwsgi/apps-available/graphite.ini /etc/uwsgi/apps-enabled/

# initialise the DB, but create no users
python /opt/graphite/webapp/graphite/manage.py syncdb --noinput

chown -R www-data:www-data /opt/graphite/webapp/ /opt/graphite/storage/

/opt/graphite/bin/carbon-cache.py start
service uwsgi restart
#service nginx restart