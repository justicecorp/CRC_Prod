async function UpdateVisitorCounter(){
    // CANNOT USE THE $ left bracket var right bracket notation in this script. This is used by terraform for dynamic replacement.
    const url = "${APIGWURL}";
    //const fetchPromise = fetch(url, {method: "POST", cache: "no-cache"});
    let myjso = await fetch(url, {method: "POST", cache: "no-cache"})
        .then(function(response) {
            return response.text();
        }).then(function(data) {
            const myjson = JSON.parse(data);
            return myjson
        });

    if (typeof document !== 'undefined') {
        // the document variable is defined - ie. we are in a webpage
        document.getElementById("CounterVal").textContent=myjso.After;
    }
}