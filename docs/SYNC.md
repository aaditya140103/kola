# Kola — Bring Your Own Cloud Sync

Kola is local-first. Sync is an **optional transport layer** chosen and controlled by the user.

Kola does not require a Kola-hosted account or storage service. Users may connect their own storage and synchronize Kola state and, optionally, document files across devices.

## 1. Product rule

> **Local is primary. Cloud is optional transport.**

A user who never configures sync must retain the complete reading experience.

Sync must never be required for:

- opening local files;
- annotations;
- search;
- progress tracking;
- themes;
- collections;
- exports.

## 2. Initial backend targets

Kola should expose a `SyncBackend` abstraction and add providers incrementally.

Recommended backends:

- Local sync folder
- WebDAV
- Google Drive
- Microsoft OneDrive
- Dropbox
- S3-compatible object storage

A local sync folder is important because it also allows users to bring their own external synchronizer such as Syncthing, Nextcloud desktop sync, NAS software, or another file-sync utility without Kola knowing about that service.

Provider support must remain modular; core domain code must not contain Google/Dropbox/Microsoft-specific types.

## 3. Sync scopes

Users choose what leaves the device.

### State only

Synchronize:

- annotations;
- bookmarks;
- reading position;
- reading coverage;
- collections;
- tags;
- document metadata/fingerprints;
- custom themes;
- selected settings.

Document binaries remain local.

### Selected documents

State plus user-selected source documents.

### Full library

State plus all eligible managed documents.

Large-file limits and metered-network behavior must be configurable.

## 4. Do not synchronize the SQLite database file

Never place Kola's live SQLite database into a cloud folder and treat file synchronization as database replication.

Instead:

```text
Local SQLite
   -> Sync projection / change journal
   -> portable sync records
   -> optional encryption
   -> SyncBackend
   -> user's cloud
```

On another device:

```text
SyncBackend
   -> decrypt / validate
   -> merge records
   -> local SQLite transaction
```

This prevents database corruption and allows deterministic conflict handling.

## 5. Backend interface

Conceptual interface:

```dart
abstract interface class SyncBackend {
  SyncBackendCapabilities get capabilities;

  Future<void> connect();
  Future<void> disconnect();

  Future<RemoteObject?> stat(String key);
  Stream<RemoteObject> list(String prefix);

  Future<Uint8List> download(String key);
  Future<void> upload(
    String key,
    Uint8List bytes, {
    String? expectedRevision,
  });

  Future<void> delete(
    String key, {
    String? expectedRevision,
  });

  Future<RemoteDelta?> getChanges(String? cursor);
}
```

Capabilities may include:

- conditional writes / ETag support;
- delta/change tokens;
- resumable uploads;
- object versioning;
- atomic rename;
- server-side timestamps;
- maximum object size.

The sync engine must not assume every backend supports every feature.

## 6. Cloud layout

Kola should use an app-owned folder/prefix rather than scattering files through the user's cloud.

Conceptual layout:

```text
Kola/
  manifest/
    schema.json
    devices/
  state/
    documents/
    annotations/
    bookmarks/
    collections/
    themes/
    progress/
  blobs/
    <content-hash>
  tombstones/
  snapshots/
```

Exact physical representation may evolve, but the format must be versioned.

## 7. Content-addressed documents

Document binaries should be keyed by a strong content hash.

```text
blob key = hash(document bytes)
```

Benefits:

- deduplication;
- renamed files retain identity;
- same document is not uploaded repeatedly;
- metadata/annotations refer to stable content identity.

Original filenames remain metadata and can differ by device.

## 8. Sync record identity

Every mutable Kola entity should have a stable UUID.

Examples:

- annotation id;
- bookmark id;
- collection id;
- theme id;
- reading-state id/document id.

Each syncable record carries synchronization metadata such as:

```text
record_id
record_type
device_id
revision
modified_at
deleted/tombstone
payload_schema_version
```

A monotonic logical revision or hybrid logical clock is preferred over trusting wall-clock timestamps alone.

## 9. Conflict strategy

Different data needs different merge rules.

### Additive entities

Annotations/bookmarks created independently on two devices coexist because they use distinct UUIDs.

### Same-record edits

For a note edited on two offline devices:

- preserve both versions if safe automatic merge is impossible;
- present a simple conflict resolver;
- never silently discard user-authored text.

### Reading position

Default policy may choose the furthest meaningful/newest active reading state, but users must be able to return through reading history.

### Reading coverage

Coverage merges by **set union** of covered logical ranges when graph versions are compatible.

### Collections/tags

Merge by stable entity ids and membership operations rather than replacing whole lists.

### Deletion

Use tombstones so an offline device cannot resurrect deleted data simply because it reconnects later.

## 10. Sync engine

```text
Local mutation
  -> write local DB
  -> append sync journal entry
  -> background sync scheduler
  -> package changed records
  -> encrypt if enabled
  -> backend upload
  -> record remote revision/cursor
```

Pull path:

```text
backend delta/list
  -> download changed records
  -> verify/decrypt
  -> validate schema
  -> merge
  -> one local DB transaction
  -> notify application state
```

Reader interactions never wait for cloud completion.

## 11. Offline behavior

Kola remains fully writable while offline.

Sync states can be:

- Local only
- Pending upload
- Synced
- Pending download
- Conflict
- Error

Network failures must not block annotation or reading.

## 12. End-to-end encryption

Kola should offer **optional client-side encryption** before data reaches third-party storage.

When enabled:

```text
Kola record / document
   -> serialize
   -> encrypt locally
   -> upload ciphertext
```

The cloud provider should not need plaintext access to annotations or documents.

Requirements:

- authenticated encryption;
- per-vault cryptographic keys;
- user-controlled recovery secret/passphrase;
- key material stored using OS secure storage where available;
- keys are never uploaded in plaintext;
- clear recovery warning because Kola cannot recover a lost zero-knowledge key.

Exact cryptographic primitives and key derivation must be selected during security implementation and documented before release.

## 13. Vault model

A Kola sync configuration is a **Sync Vault**.

```text
SyncVault
  id
  backendType
  remoteRoot
  syncScope
  encryptionMode
  deviceId
  lastCursor
  status
```

A user may eventually have multiple vaults, but v1 sync can restrict the UI to one active vault to reduce complexity.

## 14. Multiple devices

Each Kola installation creates a random `deviceId` for sync.

The vault tracks known devices and last-seen revisions. Device names are display metadata only and may be changed locally.

Users should be able to:

- see connected devices;
- remove a device from the vault;
- force a full rescan;
- reset local sync state without deleting cloud data;
- disconnect a provider without deleting local data.

## 15. Provider authentication

OAuth-based providers should use system/browser authorization flows and least-privilege scopes.

Credentials/tokens belong in OS-provided secure storage, never the Kola SQLite database or plaintext config files.

WebDAV/S3 credentials should follow the same secure-storage rule.

## 16. Privacy UX

Before enabling sync, Kola clearly states:

- which provider is connected;
- which data categories will upload;
- whether source document files will upload;
- whether client-side encryption is enabled;
- approximate pending upload size.

No background cloud connection is made until the user configures a vault.

## 17. Metered/mobile controls

Settings should include:

- Wi-Fi only for document binaries;
- allow state sync on mobile data;
- maximum automatic file size;
- sync while charging only (optional);
- manual Sync Now;
- pause sync.

State records are small and may use a different policy from document binaries.

## 18. File availability

Cloud-backed documents may have these states:

- local;
- cloud-only;
- downloading;
- available offline;
- upload pending;
- unavailable/error.

Kola must never pretend a cloud-only document is locally available.

Optional future behavior: download-on-open while leaving document blobs evictable from local managed storage.

## 19. Security boundaries

- cloud data is untrusted input;
- validate all downloaded records;
- verify hashes before accepting document blobs;
- use bounded archive/parsing behavior after download;
- do not execute active document content;
- never deserialize arbitrary executable objects;
- provider tokens remain outside exported normal backups unless explicitly supported through secure migration.

## 20. Suggested implementation order

### Sync Phase A — protocol foundation

- stable entity UUIDs;
- sync journal;
- schema/versioned portable records;
- merge engine;
- tombstones;
- deterministic tests with two simulated devices.

### Sync Phase B — local folder backend

- easiest backend for protocol testing;
- enables Syncthing/Nextcloud/NAS workflows immediately.

### Sync Phase C — WebDAV

- broad self-hosted compatibility.

### Sync Phase D — major providers

- Google Drive;
- OneDrive;
- Dropbox.

### Sync Phase E — S3-compatible storage

- custom endpoint/region/bucket/prefix support.

### Sync Phase F — client-side encrypted vault

Encryption design can be developed earlier, but encrypted multi-device interoperability must receive dedicated security testing before it is considered stable.

## 21. Non-goals

- no mandatory Kola cloud;
- no server required for local reading;
- no collaboration/multi-user document editing in the initial sync design;
- no automatic upload of files until user explicitly enables it;
- no sync by copying the live SQLite database;
- no provider-specific behavior leaking into document/domain logic.

## 22. Success condition

A user should be able to install Kola on two devices, connect the same personally controlled cloud vault, read and annotate offline on either device, reconnect later, and have progress and annotations converge without losing data or handing control of the library to Kola infrastructure.
