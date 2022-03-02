# Using Kubernetes Volume Snapshots to backup CouchDB

Backing up CouchDB can be accomplished by creating a "snapshot" of the persistent volume involved using Kubernetes [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) feature. This snapshot can then be used either to provision a new volume (pre-populated with the snapshot data) or to restore an existing volume to a previous state (represented by the snapshot).

**Important Note:** As can be read in the official Kubernetes docs, API Objects VolumeSnapshot, VolumeSnapshotContent, and VolumeSnapshotClass are CRDs, and as Kubernetes version 1.23, **not part of the core API** yet.
Also VolumeSnapshot support is only available for CSI drivers. More information about this can be found [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

To install the snapshotter, [these](https://github.com/kubernetes-csi/external-snapshotter/tree/master/client/config/crd) files must be applied first. More information about the external snapshotter [here](https://github.com/kubernetes-csi/external-snapshotter).


After installing the snapshotter's CRDs, the procedure to take and backup a PVC from a snapshot would be:

1. Create a VolumeSnapshotClass object to tell Kubernetes which driver file to use when creating snapshots with `kubectl create -f snapshot_class.yaml`:

    ```yaml
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshotClass
    metadata:
      name: couchdb-snapshot-class
    driver: hostpath.csi.k8s.io
    deletionPolicy: Delete
    parameters:
    ```

2. Create a VolumeSnapshot for the CouchDB PersistentVolumeClaim with `kubectl create -f volumesnapshot.yaml`

    ```yaml
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshot
    metadata:
      name: couchdb-snapshot
      namespace: sd
    spec:
      volumeSnapshotClassName: couchdb-snapshot-class
      source:
        persistentVolumeClaimName: couchdb-pvc-test
    ```

In the above `spec`, `persistentVolumeClaimName: pvc-data` indicates that the user wants to snapshot the couchdb-pvc-test PVC. `source` would be the PVC to take a snapshot of. In `SD`'s example it could be: `database-storage-uoc-couchdb-0`.


3. Restoring the snapshot can be done by creating a new PersistentVolumeClaim that refers to the snapshot by calling `kubectl create -f restore_file.yaml`

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim 
    metadata:
      name: pvc-couchdb-snapshot-restored
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
      dataSource:
        name: couchdb-snapshot
        kind: VolumeSnapshot
        apiGroup: snapshot.storage.k8s.io
    ```
After that there will be a PVC called pvc-couchdb-snapshot-restored, based on the PVC database-storage-uoc-couchdb-0 with all its data from that point that could be referenced from a new CouchDB instance. In SD's case, after a disaster, the `metadata.name` parameter could be set to `database-storage-uoc-couchdb-0`. Once the new PVC is bound, CouchDB would be running with its state restored properly.

For more details and examples of snapshot use in Kubernetes, see the [official docs](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

In practice, it is a bit cumbersome to take a snapshot by manually creating the YAML. There are third party tools like [Velero](https://velero.io/) is able to help us to automate the process.