import { sdk } from "./deps.ts";

export default async function (req: any, res: any) {
    const client = new sdk.Client();
    const avatar = new sdk.Avatars(client);
    const storage = new sdk.Storage(client);
    
    if (!req.variables['APPWRITE_FUNCTION_ENDPOINT'] || !req.variables['APPWRITE_FUNCTION_API_KEY']) {
        res.send("It did not work");
    }
    else {
        client
            .setEndpoint(req.variables['APPWRITE_FUNCTION_ENDPOINT'] as string)
            .setProject(req.variables['APPWRITE_FUNCTION_PROJECT_ID'] as string)
            .setKey(req.variables['APPWRITE_FUNCTION_API_KEY'] as string);
    }

    const userData = JSON.parse(req.variables["APPWRITE_FUNCTION_EVENT_DATA"]);
    
    const database = new sdk.Databases(client);
    await database.createDocument("632373f9558081f658f3", "6324aa721d69d51a3b32", "unique()", {
        "userId": userData["$id"],
        "name": userData["name"],
    });
    
    const response = await avatar.getInitials(userData["name"], 40, 40);
    const filename = `${userData["$id"]}.png`;
    await storage.createFile("632724ad7a044e3c080a", "unique()", new sdk.InputFile(await (await response.blob()).stream(), filename, await response.blob.length));
}