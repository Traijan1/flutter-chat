import { Query } from "https://deno.land/x/appwrite@6.0.0/mod.ts";
import { sdk } from "./deps.ts";

export default async function (req: any, res: any) {
  const client = new sdk.Client();
  const database = new sdk.Databases(client);

  if (!req.variables['APPWRITE_FUNCTION_ENDPOINT'] || !req.variables['APPWRITE_FUNCTION_API_KEY']) {
    console.warn("Environment variables are not set. Function cannot use Appwrite SDK.");
  } else {
    client
      .setEndpoint(req.variables['APPWRITE_FUNCTION_ENDPOINT'] as string)
      .setProject(req.variables['APPWRITE_FUNCTION_PROJECT_ID'] as string)
      .setKey(req.variables['APPWRITE_FUNCTION_API_KEY'] as string);
  }

  const data = JSON.parse(req.variables["APPWRITE_FUNCTION_EVENT_DATA"]);

  const list = await database.listDocuments("632373f9558081f658f3", "6324aa721d69d51a3b32", [
    Query.equal("userId", data["name"].replaceAll(".png", ""))
  ]);

  const user = list.documents[0];

  await database.updateDocument("632373f9558081f658f3", "6324aa721d69d51a3b32", user.$id, {
    "avatar": data["$id"]
  });
}