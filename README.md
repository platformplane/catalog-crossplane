

## TODO

- Wording PostgreSQLServerComposite?

- static username: postgres (connection details key)
- static database: postgres (connection details key)
- static host: => DNS NAME (servicename + namespace)
- static port: 5432
- static uri: =>  []byte(fmt.Sprintf("postgresql://%s:%s@%s:%s/%s", username, password, host, port, database))

- doublecheck delete statefulset volume on helm delete