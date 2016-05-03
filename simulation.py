import random


def random_network(n, a, b):
    return {i: random_delegates(n, i, a, b) for i in range(n)}

def random_delegates(n, i, a, b):
    x = random.randint(a, b)
    l = set()
    while len(l) < x:
        y = random.randint(0, n - 1)
        if y != i:
            l.add(y)
    return l


def simulate(n, a, b, p):
    network = random_network(n, a, b)

    num_delegations_by_user = {}
    for delegations_from_users in network.values():
        for user in delegations_from_users:
            if user not in num_delegations_by_user:
                num_delegations_by_user[user] = 0
            num_delegations_by_user[user] += 1

    voting_users = set(filter(lambda _: random.random() < p, network.keys()))

    total_power = 0

    for user, delegations_from_users in network.items():
        if user in voting_users:
            total_power += 1
            for from_user in delegations_from_users:
                if from_user not in voting_users:
                    total_power += 1 / num_delegations_by_user[from_user]

    return total_power

n, a, b, p = 1000, 0, 8, 0.2
rs = [simulate(n, a, b, p) for i in range(100)]

print(sum(rs) / len(rs))
