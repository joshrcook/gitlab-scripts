@module("dotenv") external dotenvConfig: unit => unit = "config"
dotenvConfig()

module Response = {
  type t<'data>
  @send external json: t<'data> => Promise.t<'data> = "json"
}

type mergeRequest = {"title": string, "web_url": string}

type payloadResult<'responseType> = (. string) => Js.Promise.t<Response.t<'responseType>>

module MergeRequestsByGroup = {
  @module external fetch: payloadResult<array<mergeRequest>> = "node-fetch"
  @val external gitlabToken: option<string> = "process.env.GITLAB_ACCESS_TOKEN"
  @val external gitlabUrl: option<string> = "process.env.GITLAB_URL"

  let token = gitlabToken->Belt.Option.getWithDefault("")
  let baseUrl = gitlabUrl->Belt.Option.getWithDefault("")

  let get = groupId => {
    let requestUrl = `${baseUrl}/groups/${groupId}/merge_requests?state=opened&private_token=${token}`
    requestUrl->Js.log2("requestUrl")
    fetch(. requestUrl)->Promise.then(res => res->Response.json)
  }
}

let _ = {
  MergeRequestsByGroup.get("4")
  ->Promise.then(data => {
    data
    ->Belt.Array.keep(mr =>
      mr["title"]->Js.String2.includes("Auto created") && mr["title"]->Js.String2.includes("master")
    )
    ->Belt.Array.map(mr => mr["web_url"])
    ->Js.log2("open merge requests")

    Promise.resolve()
  })
  ->ignore
}
