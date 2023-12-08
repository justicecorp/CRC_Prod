async function UpdateVisitorCounter(){
    // CANNOT USE THE ${var} notation in this script. This is used by terraform for dynamic replacement.
    const url = "${APIGWURL}";
    //const fetchPromise = fetch(url, {method: "POST", cache: "no-cache"});
    let myjso = await fetch(url, {method: "POST", cache: "no-cache"})
        .then(function(response) {
            return response.text();
        }).then(function(data) {
            const myjson = JSON.parse(data);
            return myjson
        });
    console.log("--AfterFetch--");
    console.log(`The result of the call = ${myjso.Status}`);
    console.log(`The Counter Before the visit = ${myjso.Before}`);
    console.log(`The Counter After the visit = ${myjso.After}`);

    if (typeof document !== 'undefined') {
        // the document variable is defined - ie. we are in a webpage
        document.getElementById("CounterVal").textContent=myjso.After;
    }
}