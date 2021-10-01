export KUBECONFIG=/home/centos/admin.conf
kubectl get svc -A | grep -i load | awk '{print $1 " " $2}' > /home/centos/loadbalancerservices.txt
if [ -s /home/centos/loadbalancerservices.txt ]; then
  echo "Found the following services of type loadbalancer. Deleting them"
  cat /home/centos/loadbalancerservices.txt
  while read service; do kubectl delete svc -n $service; done < /home/centos/loadbalancerservices.txt 
else
  echo "Nothing to delete"
fi
exit
