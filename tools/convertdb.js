var fs = require('fs');

var contents = JSON.parse(fs.readFileSync('export.json', 'utf-8'));

const groupID = "abc123";

const groups = {
    "hamptons": {
        "secret": "whitehouse",
        "groupID": groupID
    }
}

const userIds =
    Object.keys(contents)
        .filter(it => it != "users");


// Pass 1 - create user fields
var hamptons =
    userIds.reduce( (acc, userId) => {
        // overwrite with any existing data
        let user = Object.assign({claimed: {}, ideas: {}}, contents[userId].meta)

        let presents = contents[userId].presents || {};

        acc.users[userId] = user;
        acc.presents[userId] = {};
        return acc;
    }, {users: {}, presents: {}})

// Pass 2
// Now we know that "claimed" will alwasy exist
var hamptons2 =
    userIds.reduce( (acc, userId) => {
        let presents = contents[userId].presents || {};

        for (pId in presents) {
            const present = presents[pId];
            if (present.takenBy) {
                acc.users[present.takenBy]["claimed"][pId] = {
                    purchased: !!present.purchased
                }
            }
            delete presents[pId]['purchased']
        }
        acc.presents[userId] = Object.assign(presents, {name: contents[userId].meta.name});
        return acc;
    }, hamptons)

let res = {};
res["groups"] = groups;
res[groupID] = hamptons

fs.writeFileSync('newdb.json', JSON.stringify(res,4));
