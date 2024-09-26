# prometheus setup script
Prometheus installer

## Installation

- Clone the repository

```
git clone 
```
- Change into the diretory

```
cd Prometheus-setup-script
```

- Run installer script with `sudo` privileges

```
sudo ./setup_prometheus.sh
```

Check status of the prometheus service to make sure it is running
```
sudo systemctl status prometheus.service
```
The output should look like this

`● prometheus.service - Prometheus Service
     Loaded: loaded (/etc/systemd/system/prometheus.service; enabled; vendor preset: enabled)
     Active: active (running) ...
     ....`

## Configuration file

Copy the `sample_prometheus.yml` to config directory and restart prometheus service

```
sudo cp sample_prometheus.yml /etc/prometheus/prometheus.yml

sudo systemctl restart prometheus.service
```

## Web Overview

When the exporter is running, open browser and go to `http://localhost:9090/metrics` or `http://<your-server-ip>:9090/metrics`


In case you don't get reponse, please check your firewall.


