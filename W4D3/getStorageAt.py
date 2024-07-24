
import hashlib
from web3 import Web3
http_url="https://ethereum-sepolia-rpc.publicnode.com"
w3 = Web3(Web3.HTTPProvider(http_url))
ers_address=w3.toChecksumAddress("0xb9202C30f49bb474A062389f2C0f873E9b64802f")

def get_slot_data():
    """
    11个数组元素，每个元素占用2个slot，所以一共22个slot存储了这11个元素的所有数据
    :return:
    """
    storage_data=[]
    star_slot_index=hash_slot()
    end_slot_index=star_slot_index+22
    for i in range(star_slot_index,end_slot_index):
        user_storage_data = w3.eth.getStorageAt(ers_address, i)
        storage_data.append(w3.toHex(user_storage_data))

    return storage_data

def handle_fist_data(data):
    address_hex = data[-40:]  # 地址占42个字符（21字节）
    uint64_hex = data[-56:-40]  # uint64占16个字符（8字节）

    # 将地址转换为十六进制字符串
    user_address = Web3.toChecksumAddress(address_hex)
    #
    # # 将uint64转换为十进制数
    startTime = int(uint64_hex, 16)
    return user_address,startTime


def handle_second_data(data):
    amount_hex = data[-64:]  # 地址占42个字符（21字节）
    amount = int(amount_hex, 16)
    return amount


def parse_data():
    parse_list=[]
    data =get_slot_data()
    for i in range(len(data)):
        if i%2 ==0:
            parse_list.append(handle_fist_data(data[i]))
        else:
            parse_list.append(handle_second_data(data[i]))

    return parse_list

def hash_slot():
    """
    合约中LockInfo结构体在构建函数中循环运行11次就会生成一个拥有11个元素的数组，
    该结构体是这个合约中第一个变量，所以slot0存储的是keccak(0)的值，
    指向的是_locks数组第一个元素0的前2个元素，因为每个数组的结构是
    【 address user;uint64 startTime; uint256 amount;】address占20个字节，uint64占8个字节
    uint256占32个字节，一个slot32个字节，所以每个数组占用2个slot
    :return:
    """
    input_data = "0x0000000000000000000000000000000000000000000000000000000000000000"

    data_bytes = Web3.toBytes(hexstr=input_data)

    hashed_data = Web3.keccak(data_bytes)

    hashed_data_hex = Web3.toHex(hashed_data)

    star_slot_index = int(hashed_data_hex, 16)

    return star_slot_index


def master():
    _data=parse_data()
    step=2
    result=[_data[i:i+step] for i in range(0,len(_data),step)]
    for idx, item  in enumerate(result):
        _lock = item[0]
        user = _lock[0]
        starttime = _lock[1]
        amount = item[1]
        print(f"lock[{idx}] user:{user} , starttime:{starttime}，amount:{amount}")

if __name__ == '__main__':
    master()
