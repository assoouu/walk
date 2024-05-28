import Web3 from 'web3';
import HotelBooking from '../contracts/HotelBooking.json';

let web3;
let hotelBooking;

// 사용자가 MetaMask와 같은 Ethereum 지갑을 가지고 있는지 확인
if (window.ethereum) {
    // 최신 버전의 Web3 객체를 생성하고, 사용자의 Ethereum 계정에 접근 요청
    web3 = new Web3(window.ethereum);
    window.ethereum.request({ method: 'eth_requestAccounts' })
        .then(accounts => {
            console.log('Accounts:', accounts); // 사용자의 계정을 콘솔에 출력
        })
        .catch(error => {
            console.error('Error requesting accounts:', error); // 계정 요청 중 오류 발생 시 콘솔에 출력
        });
} else if (window.web3) {
    // 이전 버전의 Web3가 이미 존재하는 경우, 기존 공급자를 사용하여 Web3 객체 생성
    web3 = new Web3(window.web3.currentProvider);
} else {
    console.log('Non-Ethereum browser detected. You should consider trying MetaMask!'); // MetaMask가 설치되지 않은 경우 경고 메시지 출력
}

// 스마트 계약을 설정하는 비동기 함수
const setupContract = async () => {
    try {
        const networkId = await web3.eth.net.getId(); // 현재 네트워크 ID 가져오기
        const deployedNetwork = HotelBooking.networks[networkId]; // 현재 네트워크에 배포된 계약 정보 가져오기
        if (!deployedNetwork) {
            throw new Error("Contract not deployed on the current network"); // 현재 네트워크에 스마트 계약이 배포되지 않은 경우 오류 발생
        }
        // 스마트 계약 인스턴스를 생성하여 hotelBooking 변수에 할당
        hotelBooking = new web3.eth.Contract(HotelBooking.abi, deployedNetwork.address);
    } catch (error) {
        console.error("Error in setupContract:", error); // 스마트 계약 설정 중 오류 발생 시 콘솔에 출력
    }
};

export { web3, hotelBooking, setupContract }; // web3, hotelBooking, setupContract 함수를 내보내기
