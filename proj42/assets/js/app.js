// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import socket from "./socket"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

$(document).ready(function() {
    $("#registerButton").click(function() {
        var username = $("#registerUsername").val()
        var password = $("#registerPassword").val()
        var channel = socket.channel("user:register", {username: username, password: password})
        channel.join()
            .receive("ok", resp => {
                alert("Your user id is " + resp + ".")
                console.log("Register Successfully", resp)
                window.location.replace("http://localhost:4000/info/" + resp);
            })
            .receive("error", resp =>{
                alert("Unable to register: " + resp["reason"])
                console.log("Register Failure", resp)
            })
    })

    $("#loginButton").click(function() {
        var userid = parseInt($("#loginUserid").val())
        var password = $("#loginPassword").val()
        var channel = socket.channel("user:login", {userid: userid, password: password})
        channel.join()
            .receive("ok", resp => {
                console.log("Login Successfully", resp)
                window.location.replace("http://localhost:4000/info/" + userid);
            })
            .receive("error", resp =>{
                alert("Unable to login: " + resp["reason"])
                console.log("Login Failure", resp)
            })
    })

    $("#subscribeButton").click(function() {
        var currenturl = window.location.href
        var lastPart = currenturl.split("/").pop()
        var channel = socket.channel("user:subscribe", {})
        channel.join()
            .receive("ok", resp => {
                console.log("Turn to subscribe page")
                window.location.replace("http://localhost:4000/subscribe/" + lastPart);
            })
    })

    $("#subscribeAndRefreshButton").click(function() {
        var currenturl = window.location.href
        var lastPart = currenturl.split("/").pop()
        var subscribeUserid = parseInt($("#subscribeUserid").val())
        var channel = socket.channel("user:subscribe_and_refresh", {userid: parseInt(lastPart, 10), subscribeUserid: subscribeUserid})
        channel.join()
            .receive("ok", resp => {
                console.log("Subscribe successfully and turn back to main page")
                alert("Successfully subscribed")
                window.location.replace("http://localhost:4000/info/" + lastPart);
            })
            .receive("error", resp =>{
                alert(resp["reason"])
                console.log("Subscribe Failure", resp)
            })
    })

    $("#tweetButton").click(function() {
        var currenturl = window.location.href
        var lastPart = currenturl.split("/").pop()
        var channel = socket.channel("user:tweet", {})
        channel.join()
            .receive("ok", resp => {
                console.log("Turn to tweet page")
                window.location.replace("http://localhost:4000/tweet/" + lastPart);
            })
    })

    $("#tweetAndRefreshButton").click(function() {
        var currenturl = window.location.href
        var lastPart = currenturl.split("/").pop()
        var tweetContent = $("#tweetContent").val()
        var hashTag = $("#hashTag").val()
        var mention = $("#mention").val()
        var channel = socket.channel("user:tweet_and_refresh", 
            {userid: parseInt(lastPart, 10), tweet: tweetContent, hashTag: hashTag, mention: mention})
        channel.join()
            .receive("ok", resp => {
                console.log("Tweet successfully and turn back to main page")
                alert("Successfully tweeted")
                window.location.replace("http://localhost:4000/info/" + lastPart);
            })
    })

    $("#searchButton").click(function() {
        var currenturl = window.location.href
        var lastPart = currenturl.split("/").pop()
        var channel = socket.channel("user:search", {})
        channel.join()
            .receive("ok", resp => {
                console.log("Turn to search page")
                window.location.replace("http://localhost:4000/search/" + lastPart);
            })
    })

    $("#backToMainPage").click(function() {
        var currenturl = window.location.href
        var lastPart = currenturl.split("/").pop()
        var channel = socket.channel("user:back", {})
        channel.join()
            .receive("ok", resp => {
                console.log("Turn to main page")
                window.location.replace("http://localhost:4000/info/" + lastPart);
            })
    })

    $("#subsearch").click(function() {
        var userid = parseInt($("#inputsubsearch").val())
        var channel = socket.channel("user:subsearch", {userid: userid})
        channel.join()
            .receive("ok", resp =>{
                console.log("Searched", resp)
                $("#searchresults").empty()
                var i = 0
                for (; i < resp.length; i++) {
                    if (resp[i][0] == "tweet") {
                        $("#searchresults").append("<hr />");
                        $("#searchresults").append("<div>");
                        $("#searchresults").append("<p>user " + resp[i][2] + "(" + resp[i][1] + ") </p>");
                        $("#searchresults").append("<p>Content: " + resp[i][3] + "</p>");
                        $("#searchresults").append("<p>User Mentioned: ");
                        var j = 0
                        for (; j < resp[i][6].length; j++) {
                            $("#searchresults").append(" " + resp[i][6][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("<p>Hashtag: </p>");
                        for (j = 0; j < resp[i][5].length; j++) {
                            $("#searchresults").append(" " + resp[i][5][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("</div>");
                    } else {
                        $("#searchresults").append("<div>");
                        $("#searchresults").append("<p>user " + resp[i][2] + "(" + resp[i][1] + ") retweeted from " + resp[i][5] + "(" + resp[i][4] + ")" + " </p>");
                        $("#searchresults").append("<p>Content: " + resp[i][7] + "</p>");
                        $("#searchresults").append("<p>User Mentioned: ");
                        var j = 0
                        for (; j < resp[i][9].length; j++) {
                            $("#searchresults").append(" " + resp[i][6][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("<p>Hashtag: </p>");
                        for (j = 0; j < resp[i][8].length; j++) {
                            $("#searchresults").append(" " + resp[i][5][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("</div>");
                    }
                }
            })
            .receive("error", resp =>{
                alert("No such user")
                console.log("Search Failure", resp)
            })
    })

    $("#mentionsearch").click(function() {
        var userid = parseInt($("#inputmentionsearch").val())
        var channel = socket.channel("user:mentionsearch", {userid: userid})
        channel.join()
            .receive("ok", resp => {
                console.log("Searched", resp)
                $("#searchresults").empty()
                var i = 0
                for (; i < resp.length; i++) {
                    if (resp[i][0] == "tweet") {
                        $("#searchresults").append("<hr />");
                        $("#searchresults").append("<div>");
                        $("#searchresults").append("<p>user " + resp[i][2] + "(" + resp[i][1] + ") </p>");
                        $("#searchresults").append("<p>Content: " + resp[i][3] + "</p>");
                        $("#searchresults").append("<p>User Mentioned: ");
                        var j = 0
                        for (; j < resp[i][6].length; j++) {
                            $("#searchresults").append(" " + resp[i][6][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("<p>Hashtag: </p>");
                        for (j = 0; j < resp[i][5].length; j++) {
                            $("#searchresults").append(" " + resp[i][5][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("</div>");
                    } else {
                        $("#searchresults").append("<div>");
                        $("#searchresults").append("<p>user " + resp[i][2] + "(" + resp[i][1] + ") retweeted from " + resp[i][5] + "(" + resp[i][4] + ")" + " </p>");
                        $("#searchresults").append("<p>Content: " + resp[i][7] + "</p>");
                        $("#searchresults").append("<p>User Mentioned: ");
                        var j = 0
                        for (; j < resp[i][9].length; j++) {
                            $("#searchresults").append(" " + resp[i][6][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("<p>Hashtag: </p>");
                        for (j = 0; j < resp[i][8].length; j++) {
                            $("#searchresults").append(" " + resp[i][5][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("</div>");
                    }
                }
            })
            .receive("error", resp =>{
                alert("No result found")
                console.log("Search Failure", resp)
            })
    })

    $("#hashtagsearch").click(function() {
        var hashtag = $("#inputhashtagsearch").val()
        var channel = socket.channel("user:hashtagsearch", {hashtag: hashtag})
        channel.join()
            .receive("ok", resp =>{
                console.log("Searched", resp)
                $("#searchresults").empty()
                var i = 0
                for (; i < resp.length; i++) {
                    if (resp[i][0] == "tweet") {
                        $("#searchresults").append("<hr />");
                        $("#searchresults").append("<div>");
                        $("#searchresults").append("<p>user " + resp[i][2] + "(" + resp[i][1] + ") </p>");
                        $("#searchresults").append("<p>Content: " + resp[i][3] + "</p>");
                        $("#searchresults").append("<p>User Mentioned: ");
                        var j = 0
                        for (; j < resp[i][6].length; j++) {
                            $("#searchresults").append(" " + resp[i][6][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("<p>Hashtag: </p>");
                        for (j = 0; j < resp[i][5].length; j++) {
                            $("#searchresults").append(" " + resp[i][5][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("</div>");
                    } else {
                        $("#searchresults").append("<div>");
                        $("#searchresults").append("<p>user " + resp[i][2] + "(" + resp[i][1] + ") retweeted from " + resp[i][5] + "(" + resp[i][4] + ")" + " </p>");
                        $("#searchresults").append("<p>Content: " + resp[i][7] + "</p>");
                        $("#searchresults").append("<p>User Mentioned: ");
                        var j = 0
                        for (; j < resp[i][9].length; j++) {
                            $("#searchresults").append(" " + resp[i][6][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("<p>Hashtag: </p>");
                        for (j = 0; j < resp[i][8].length; j++) {
                            $("#searchresults").append(" " + resp[i][5][j]);
                        }
                        $("#searchresults").append("</p>");
                        $("#searchresults").append("</div>");
                    }
                }
            })
            .receive("error", resp =>{
                alert("No result found")
                console.log("Search Failure", resp)
            })
    })

})

function getInfo(){
    var channel = socket.channel("user:info", {})
    channel.join()
        .receive("ok", resp => {
            alert(resp)
        })
}
