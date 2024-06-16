<img src="server/priv/static/images/logo.png" width="200"/>

# Ingest


DeepLynx Ingest is a web application designed to give project managers the ability to quickly and accurately gather data for their projects. With a focus on speed and metadata collection, Ingest allows projects to continually build their data storage while maintaining essential information right alongside the data.


Ingest consists of two parts.


## [Ingest Server](/server/README.md)


The central Ingest server is the management platform for data transfers and metadata collection. Here project managers create and manage the data collection efforts of their various projects. They are able to build requests for data and design metadata collection forms to enable simple data curation at time of ingestion.

Users are able to upload files directly using the web interface on the central server. Eventually, they will be able to use both the web ui and the client application to accomplish these uploads. At time of writing (June 2024) only the web ui currently accepts uploads.


The central server is written in Elixir and uses the Phoenix web framework.


## [Ingest Client](/client/readme.md) *alpha preview*



The DeepLynx Ingest client is a cross-platform application designed to enable high-speed UDP file transfer from the computer it's installed on to either the central server or other DeepLynx Ingest clients. It integrates directly with the central server, with the central server acting as the UI for the application vs. building a native UI for each platform.

The client is written in Rust and is currently in alpha preview state. The long-term goal of this application is take the place of tools like Globus and Jetstream.





![inl_logo](server/priv/static/images/inllogo.png)