/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  // Create events collection
  const eventsCollection = new Collection({
    name: "events",
    type: "base",
    system: false,
    schema: [
      {
        name: "name",
        type: "text",
        required: true,
        options: {
          min: 1,
          max: 200,
        },
      },
      {
        name: "createdBy",
        type: "text",
        required: true,
        options: {
          min: null,
          max: null,
        },
      },
      {
        name: "qrCode",
        type: "text",
        required: true,
        options: {
          min: null,
          max: null,
        },
      },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_qrCode ON events (qrCode)",
    ],
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
  });

  return Dao(db).saveCollection(eventsCollection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("events");
  return dao.deleteCollection(collection);
});

migrate((db) => {
  // Create participants collection
  const participantsCollection = new Collection({
    name: "participants",
    type: "base",
    system: false,
    schema: [
      {
        name: "eventId",
        type: "relation",
        required: true,
        options: {
          collectionId: "", // Will be set after events collection exists
          cascadeDelete: true,
          minSelect: null,
          maxSelect: 1,
          displayFields: ["name"],
        },
      },
      {
        name: "userId",
        type: "text",
        required: true,
        options: {
          min: null,
          max: null,
        },
      },
      {
        name: "userName",
        type: "text",
        required: true,
        options: {
          min: 1,
          max: 100,
        },
      },
      {
        name: "shotsRemaining",
        type: "number",
        required: true,
        options: {
          min: 0,
          max: 10,
          noDecimal: true,
        },
      },
    ],
    indexes: [],
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
  });

  // Get events collection ID
  const eventsCollection = Dao(db).findCollectionByNameOrId("events");
  participantsCollection.schema[0].options.collectionId = eventsCollection.id;

  return Dao(db).saveCollection(participantsCollection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("participants");
  return dao.deleteCollection(collection);
});

migrate((db) => {
  // Create photos collection
  const photosCollection = new Collection({
    name: "photos",
    type: "base",
    system: false,
    schema: [
      {
        name: "eventId",
        type: "relation",
        required: true,
        options: {
          collectionId: "",
          cascadeDelete: true,
          minSelect: null,
          maxSelect: 1,
          displayFields: ["name"],
        },
      },
      {
        name: "userId",
        type: "text",
        required: true,
        options: {
          min: null,
          max: null,
        },
      },
      {
        name: "image",
        type: "file",
        required: true,
        options: {
          maxSelect: 1,
          maxSize: 10485760, // 10MB
          mimeTypes: [
            "image/jpeg",
            "image/png",
            "image/jpg",
          ],
          thumbs: [
            "300x300",
            "600x600",
          ],
          protected: false,
        },
      },
    ],
    indexes: [],
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
  });

  // Get events collection ID
  const eventsCollection = Dao(db).findCollectionByNameOrId("events");
  photosCollection.schema[0].options.collectionId = eventsCollection.id;

  return Dao(db).saveCollection(photosCollection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("photos");
  return dao.deleteCollection(collection);
});
