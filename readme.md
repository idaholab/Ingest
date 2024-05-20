# DeepLynx Ingest

--------------

DeepLynx Ingest is a full application designed to give project managers the ability to quickly and accurately gather data for their projects. With a focus on speed and metadata collection, Ingest allows projects to perform some simple data curation and manipulation at the time of data ingestion.


## [Ingest Server](/server/README.md)

-------------

The central Ingest server is the management platform for data transfers. Here project managers create and manage the data collection efforts of their various projects. They are able to build requests for data and design metadata collection platforms to enable simple data curation at time of ingestion.

Users are able to upload files directly using the web interface on the central server, or to use the client application (talked about later in this readme).

The Ingest central server also acts as a TURN and STUN server for peer to peer connections for the high speed file transfer portion of DeepLynx Ingest.

The central server is written in Elixir and uses the Phoenix web framework.


## [Ingest Client](/client/readme.md)

------------------


The DeepLynx Ingest client is a cross-platform application designed to enable high-speed UDP file transfer from the computer it's installed on to either the central server or other DeepLynx Ingest clients. It integrates directly with the central server, with the central server acting as the UI for the application vs. building a native UI for each platform.

The client is written in Rust.