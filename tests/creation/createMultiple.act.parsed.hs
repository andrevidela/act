[Transition "create_a" "B" create_a() [Iff (AlexPn 117 10 1) [EEq (AlexPn 134 11 14) (EnvExp (AlexPn 124 11 4) Callvalue) (IntLit 0)]] (Branch (AlexPn 0 0 0) (BoolLit True) [Leaf (AlexPn 0 0 0) (BoolLit True) (Post (Just [Rewrite (Entry (AlexPn 151 14 4) "a" []) (ENewaddr (AlexPn 156 14 9) (EnvExp (AlexPn 164 14 17) Address) (EnvExp (AlexPn 170 14 23) Nonce))]) [ExtCreates "A" (ENewaddr (AlexPn 242 17 14) (EnvExp (AlexPn 250 17 22) Address) (EnvExp (AlexPn 256 17 28) Nonce)) [AssignVal (StorageVar uint256 "x") (IntLit 1)]] Nothing)]) Nothing,Constructor "init" "B" constructor() [] (Creates [AssignVal (StorageVar address "a") (IntLit 0)]) [] Nothing Nothing]
